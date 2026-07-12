package com.ryanladuca.myafbase.data.db

import androidx.room.Dao
import androidx.room.Database
import androidx.room.Entity
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.RoomDatabase
import kotlinx.coroutines.flow.Flow

@Entity(tableName = "bookmarks")
data class BookmarkEntity(
    @PrimaryKey val id: String,
    val baseId: String,
    val targetType: String,
    val targetId: String,
    val title: String,
    val subtitle: String?,
    val createdAt: Long = System.currentTimeMillis()
)

@Dao
interface BookmarkDao {
    @Query("SELECT * FROM bookmarks WHERE baseId = :baseId ORDER BY createdAt DESC")
    fun observeForBase(baseId: String): Flow<List<BookmarkEntity>>

    @Query("SELECT * FROM bookmarks WHERE baseId = :baseId ORDER BY createdAt DESC")
    suspend fun forBase(baseId: String): List<BookmarkEntity>

    @Query("SELECT EXISTS(SELECT 1 FROM bookmarks WHERE id = :id)")
    suspend fun exists(id: String): Boolean

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: BookmarkEntity)

    @Query("DELETE FROM bookmarks WHERE id = :id")
    suspend fun delete(id: String)

    @Query("DELETE FROM bookmarks")
    suspend fun deleteAll()
}

@Entity(tableName = "checklist_completions", primaryKeys = ["baseId", "kind", "itemId"])
data class ChecklistCompletionEntity(
    val baseId: String,
    val kind: String,
    val itemId: String,
    val completed: Boolean = true
)

@Dao
interface ChecklistDao {
    @Query("SELECT * FROM checklist_completions WHERE baseId = :baseId AND kind = :kind")
    fun observe(baseId: String, kind: String): Flow<List<ChecklistCompletionEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: ChecklistCompletionEntity)

    @Query("DELETE FROM checklist_completions WHERE baseId = :baseId AND kind = :kind AND itemId = :itemId")
    suspend fun delete(baseId: String, kind: String, itemId: String)
}

@Entity(tableName = "assignment_profile")
data class AssignmentProfileEntity(
    @PrimaryKey val baseId: String,
    val phaseRaw: String,
    val reportDateMillis: Long?,
    val pcsDateMillis: Long?,
    val updatedAtMillis: Long
)

@Dao
interface AssignmentDao {
    @Query("SELECT * FROM assignment_profile WHERE baseId = :baseId LIMIT 1")
    fun observe(baseId: String): Flow<AssignmentProfileEntity?>

    @Query("SELECT * FROM assignment_profile WHERE baseId = :baseId LIMIT 1")
    suspend fun get(baseId: String): AssignmentProfileEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: AssignmentProfileEntity)
}

@Entity(tableName = "readiness")
data class ReadinessEntity(
    @PrimaryKey val baseId: String,
    val fitnessTestDueMillis: Long?,
    val dentalDueMillis: Long?,
    val evalCloseoutDueMillis: Long?,
    val pcsWindowStartMillis: Long?,
    val pcsWindowEndMillis: Long?,
    val cacExpirationMillis: Long?,
    val clearanceRenewalMillis: Long?,
    val updatedAtMillis: Long
)

@Dao
interface ReadinessDao {
    @Query("SELECT * FROM readiness WHERE baseId = :baseId LIMIT 1")
    fun observe(baseId: String): Flow<ReadinessEntity?>

    @Query("SELECT * FROM readiness WHERE baseId = :baseId LIMIT 1")
    suspend fun get(baseId: String): ReadinessEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: ReadinessEntity)
}

@Entity(tableName = "pfra_records")
data class PfraRecordEntity(
    @PrimaryKey val id: String,
    val dateMillis: Long,
    val score: Double,
    val rating: String,
    val passed: Boolean = false,
    val kind: String = "DIAGNOSTIC",
    val note: String? = null,
    val targetTier: String? = null,
    val detailsJson: String = "",
    val gender: String = "MALE",
    val age: Int = 28,
    val heightInches: Double = 70.0,
    val waistInches: Double = 34.0,
    val cardioEvent: String = "TWO_MILE_RUN",
    val cardioValue: Double = 900.0,
    val strengthEvent: String = "PUSH_UPS",
    val strengthReps: Int = 40,
    val coreEvent: String = "SIT_UPS",
    val coreValue: Double = 45.0
)

@Dao
interface PfraDao {
    @Query("SELECT * FROM pfra_records ORDER BY dateMillis DESC")
    fun observeAll(): Flow<List<PfraRecordEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: PfraRecordEntity)

    @Query("DELETE FROM pfra_records WHERE id = :id")
    suspend fun delete(id: String)

    @Query("DELETE FROM pfra_records")
    suspend fun deleteAll()
}

@Entity(tableName = "war_entries")
data class WarEntryEntity(
    @PrimaryKey val id: String,
    val baseId: String = "",
    val dateMillis: Long,
    val title: String,
    val body: String,
    val category: String = "general",
    val impact: String = "",
    val tags: String = "",
    val hours: Double = 0.0,
    val awardDeadlineMillis: Long? = null
)

@Dao
interface WarDao {
    @Query("SELECT * FROM war_entries WHERE baseId = :baseId OR baseId = '' ORDER BY dateMillis DESC")
    fun observeForBase(baseId: String): Flow<List<WarEntryEntity>>

    @Query("SELECT * FROM war_entries ORDER BY dateMillis DESC")
    fun observeAll(): Flow<List<WarEntryEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: WarEntryEntity)

    @Query("DELETE FROM war_entries WHERE id = :id")
    suspend fun delete(id: String)

    @Query("DELETE FROM war_entries WHERE dateMillis < :cutoffMillis")
    suspend fun deleteOlderThan(cutoffMillis: Long)
}

@Entity(tableName = "war_award_deadlines")
data class WarAwardDeadlineEntity(
    @PrimaryKey val id: String,
    val baseId: String,
    val title: String,
    val deadlineMillis: Long,
    val notes: String? = null
)

@Dao
interface WarAwardDeadlineDao {
    @Query("SELECT * FROM war_award_deadlines WHERE baseId = :baseId ORDER BY deadlineMillis ASC")
    fun observeForBase(baseId: String): Flow<List<WarAwardDeadlineEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: WarAwardDeadlineEntity)

    @Query("DELETE FROM war_award_deadlines WHERE id = :id")
    suspend fun delete(id: String)
}

@Entity(tableName = "special_pays")
data class SpecialPayEntity(
    @PrimaryKey val id: String,
    val title: String,
    val dateMillis: Long,
    val notes: String?
)

@Dao
interface SpecialPayDao {
    @Query("SELECT * FROM special_pays ORDER BY dateMillis ASC")
    fun observeAll(): Flow<List<SpecialPayEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: SpecialPayEntity)

    @Query("DELETE FROM special_pays WHERE id = :id")
    suspend fun delete(id: String)
}

@Entity(tableName = "dismissals")
data class DismissalEntity(
    @PrimaryKey val id: String,
    val dismissedAtMillis: Long = System.currentTimeMillis()
)

@Dao
interface DismissalDao {
    @Query("SELECT id FROM dismissals")
    fun observeIds(): Flow<List<String>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(entity: DismissalEntity)
}

@Database(
    entities = [
        BookmarkEntity::class,
        ChecklistCompletionEntity::class,
        AssignmentProfileEntity::class,
        ReadinessEntity::class,
        WarEntryEntity::class,
        WarAwardDeadlineEntity::class,
        PfraRecordEntity::class,
        SpecialPayEntity::class,
        DismissalEntity::class
    ],
    version = 2,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun bookmarkDao(): BookmarkDao
    abstract fun checklistDao(): ChecklistDao
    abstract fun assignmentDao(): AssignmentDao
    abstract fun readinessDao(): ReadinessDao
    abstract fun warDao(): WarDao
    abstract fun warAwardDeadlineDao(): WarAwardDeadlineDao
    abstract fun pfraDao(): PfraDao
    abstract fun specialPayDao(): SpecialPayDao
    abstract fun dismissalDao(): DismissalDao
}
