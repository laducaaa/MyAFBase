package com.ryanladuca.myafbase.data.afi

import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.Locale
import kotlin.math.sqrt

object AfiEmbeddingService {
    const val EMBEDDING_DIMENSION = 512
    private const val MAX_EMBEDDING_CHARACTERS = 800

    fun embed(text: String): FloatArray? {
        val prepared = prepare(text)
        if (prepared.isBlank()) return null
        return vectorFor(prepared)
    }

    fun embedAll(
        texts: List<String>,
        onProgress: ((completed: Int, total: Int) -> Unit)? = null,
    ): List<ByteArray> {
        if (texts.isEmpty()) return emptyList()
        return texts.mapIndexed { index, text ->
            val vector = embed(text)
            val data = if (vector == null) ByteArray(0) else serialize(vector)
            if ((index + 1) % 25 == 0 || index == texts.lastIndex) {
                onProgress?.invoke(index + 1, texts.size)
            }
            data
        }
    }

    fun serialize(vector: FloatArray): ByteArray {
        val buffer = ByteBuffer.allocate(vector.size * 4).order(ByteOrder.LITTLE_ENDIAN)
        vector.forEach { buffer.putFloat(it) }
        return buffer.array()
    }

    fun deserialize(data: ByteArray): FloatArray? {
        if (data.isEmpty() || data.size % 4 != 0) return null
        val buffer = ByteBuffer.wrap(data).order(ByteOrder.LITTLE_ENDIAN)
        val floats = FloatArray(data.size / 4)
        for (i in floats.indices) {
            floats[i] = buffer.getFloat()
        }
        return floats
    }

    private fun prepare(text: String): String =
        if (text.length > MAX_EMBEDDING_CHARACTERS) text.take(MAX_EMBEDDING_CHARACTERS) else text

    private fun vectorFor(text: String): FloatArray {
        val vector = FloatArray(EMBEDDING_DIMENSION)
        val normalized = text.lowercase(Locale.US)
        val tokens = normalized.split(Regex("\\W+")).filter { it.length >= 2 }
        if (tokens.isEmpty()) {
            hashToken(normalized, vector, weight = 1f)
        } else {
            tokens.forEach { token ->
                hashToken(token, vector, weight = 1f)
                if (token.length >= 4) {
                    for (i in 0 until token.length - 2) {
                        hashToken(token.substring(i, i + 3), vector, weight = 0.5f)
                    }
                }
            }
        }
        var norm = 0f
        for (value in vector) norm += value * value
        norm = sqrt(norm)
        if (norm > 0f) {
            for (i in vector.indices) vector[i] /= norm
        }
        return vector
    }

    private fun hashToken(token: String, vector: FloatArray, weight: Float) {
        var hash = token.hashCode()
        for (i in 0 until 3) {
            hash = hash xor (hash shl 13)
            hash = hash xor (hash shr 17)
            hash = hash xor (hash shl 5)
            val index = (hash and Int.MAX_VALUE) % vector.size
            vector[index] += weight
        }
    }
}
