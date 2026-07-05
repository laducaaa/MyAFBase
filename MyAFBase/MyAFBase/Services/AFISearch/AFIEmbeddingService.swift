import Foundation
import NaturalLanguage
import os

enum AFIEmbeddingService: Sendable {
    nonisolated private static let embeddingDimension = 512

    /// Sentence embeddings get slower and less focused on very long inputs. Chunks are
    /// capped so index builds stay fast; ranking quality is dominated by the opening text.
    nonisolated private static let maxEmbeddingCharacters = 800

    /// One shared model instance for one-off embeddings (e.g. the user's query).
    /// NLEmbedding isn't documented as thread-safe, so access goes through a lock.
    nonisolated private static let sharedEmbedding = OSAllocatedUnfairLock<NLEmbedding?>(
        uncheckedState: NLEmbedding.sentenceEmbedding(for: .english)
    )

    nonisolated static func embed(_ text: String) -> [Float]? {
        sharedEmbedding.withLockUnchecked { embedding in
            guard let embedding else { return nil }
            return vector(for: text, using: embedding)
        }
    }

    /// Embeds every text in parallel across CPU cores. Each worker gets its own
    /// NLEmbedding instance so no locking is needed on the hot path.
    /// Returns serialized vectors aligned with the input order; entries that couldn't
    /// be embedded are empty `Data`.
    nonisolated static func embedAll(
        _ texts: [String],
        progress: (@Sendable (Int, Int) -> Void)? = nil
    ) async -> [Data] {
        guard !texts.isEmpty else { return [] }

        let total = texts.count
        let workerCount = max(1, min(ProcessInfo.processInfo.activeProcessorCount, 6))
        let sliceSize = (total + workerCount - 1) / workerCount
        let completedCount = OSAllocatedUnfairLock(initialState: 0)

        var results = [Data](repeating: Data(), count: total)

        await withTaskGroup(of: (start: Int, vectors: [Data]).self) { group in
            for workerIndex in 0 ..< workerCount {
                let start = workerIndex * sliceSize
                guard start < total else { continue }
                let slice = Array(texts[start ..< min(start + sliceSize, total)])

                group.addTask {
                    let embedding = NLEmbedding.sentenceEmbedding(for: .english)
                    var vectors: [Data] = []
                    vectors.reserveCapacity(slice.count)

                    for text in slice {
                        if let embedding,
                           let vector = vector(for: text, using: embedding) {
                            vectors.append(serialize(vector))
                        } else {
                            vectors.append(Data())
                        }

                        let done = completedCount.withLock { count -> Int in
                            count += 1
                            return count
                        }
                        if done % 25 == 0 || done == total {
                            progress?(done, total)
                        }
                    }

                    return (start, vectors)
                }
            }

            for await (start, vectors) in group {
                results.replaceSubrange(start ..< start + vectors.count, with: vectors)
            }
        }

        return results
    }

    nonisolated static func serialize(_ vector: [Float]) -> Data {
        var copy = vector
        return Data(bytes: &copy, count: copy.count * MemoryLayout<Float>.size)
    }

    nonisolated static func deserialize(_ data: Data) -> [Float]? {
        guard !data.isEmpty,
              data.count % MemoryLayout<Float>.size == 0 else {
            return nil
        }

        return data.withUnsafeBytes { buffer in
            let floatBuffer = buffer.bindMemory(to: Float.self)
            return Array(floatBuffer)
        }
    }

    nonisolated static var expectedDimension: Int {
        embeddingDimension
    }

    private nonisolated static func vector(for text: String, using embedding: NLEmbedding) -> [Float]? {
        let prepared = text.count > maxEmbeddingCharacters
            ? String(text.prefix(maxEmbeddingCharacters))
            : text
        guard let vector = embedding.vector(for: prepared) else { return nil }
        return vector.map(Float.init)
    }
}

enum AFIEmbeddingMath {
    nonisolated static func cosineSimilarity(_ lhs: [Float], _ rhs: [Float]) -> Float {
        guard lhs.count == rhs.count, !lhs.isEmpty else { return 0 }

        var dot: Float = 0
        var lhsNorm: Float = 0
        var rhsNorm: Float = 0

        for index in lhs.indices {
            dot += lhs[index] * rhs[index]
            lhsNorm += lhs[index] * lhs[index]
            rhsNorm += rhs[index] * rhs[index]
        }

        let denominator = (lhsNorm.squareRoot() * rhsNorm.squareRoot())
        guard denominator > 0 else { return 0 }
        return dot / denominator
    }
}
