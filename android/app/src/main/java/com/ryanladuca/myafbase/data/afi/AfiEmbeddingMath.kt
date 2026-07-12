package com.ryanladuca.myafbase.data.afi

import kotlin.math.sqrt

object AfiEmbeddingMath {
    fun cosineSimilarity(lhs: FloatArray, rhs: FloatArray): Float {
        if (lhs.size != rhs.size || lhs.isEmpty()) return 0f
        var dot = 0f
        var lhsNorm = 0f
        var rhsNorm = 0f
        for (i in lhs.indices) {
            dot += lhs[i] * rhs[i]
            lhsNorm += lhs[i] * lhs[i]
            rhsNorm += rhs[i] * rhs[i]
        }
        val denominator = sqrt(lhsNorm) * sqrt(rhsNorm)
        if (denominator <= 0f) return 0f
        return dot / denominator
    }
}
