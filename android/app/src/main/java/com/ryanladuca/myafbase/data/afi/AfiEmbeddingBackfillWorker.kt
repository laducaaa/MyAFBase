package com.ryanladuca.myafbase.data.afi

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.ryanladuca.myafbase.MyAFBaseApplication

class AfiEmbeddingBackfillWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {
    override suspend fun doWork(): Result {
        val app = applicationContext as? MyAFBaseApplication ?: return Result.failure()
        return try {
            app.container.afiSearchRepository.ensureLoaded()
            app.container.afiSearchRepository.runEmbeddingBackfill()
            Result.success()
        } catch (_: Exception) {
            Result.retry()
        }
    }

    companion object {
        private const val UNIQUE_WORK = "afi_embedding_backfill"

        fun enqueue(context: Context) {
            val request = OneTimeWorkRequestBuilder<AfiEmbeddingBackfillWorker>().build()
            WorkManager.getInstance(context).enqueueUniqueWork(
                UNIQUE_WORK,
                ExistingWorkPolicy.KEEP,
                request,
            )
        }
    }
}
