package com.example.flutter_my_app_main

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log

private const val TAG = "AppBlockDatabase"
private const val DATABASE_NAME = "app_block.db"
private const val DATABASE_VERSION = 1
private const val TABLE_BLOCKED_APPS = "blocked_apps"
private const val COLUMN_PACKAGE_NAME = "package_name"
private const val COLUMN_IS_BLOCKED = "is_blocked"

class AppBlockDatabase(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    override fun onCreate(db: SQLiteDatabase) {
        val createTable = """
            CREATE TABLE $TABLE_BLOCKED_APPS (
                $COLUMN_PACKAGE_NAME TEXT PRIMARY KEY,
                $COLUMN_IS_BLOCKED INTEGER NOT NULL DEFAULT 1
            )
        """.trimIndent()
        db.execSQL(createTable)
        Log.d(TAG, "Database created with table: $TABLE_BLOCKED_APPS")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_BLOCKED_APPS")
        onCreate(db)
    }

    fun setAppBlocked(packageName: String, isBlocked: Boolean): Boolean {
        return try {
            val db = writableDatabase
            if (isBlocked) {
                val values = ContentValues().apply {
                    put(COLUMN_PACKAGE_NAME, packageName)
                    put(COLUMN_IS_BLOCKED, 1)
                }
                db.insertWithOnConflict(TABLE_BLOCKED_APPS, null, values, SQLiteDatabase.CONFLICT_REPLACE)
            } else {
                db.delete(TABLE_BLOCKED_APPS, "$COLUMN_PACKAGE_NAME = ?", arrayOf(packageName))
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error setting app blocked status: ${e.message}")
            false
        }
    }

    fun isAppBlocked(packageName: String): Boolean {
        return try {
            val db = readableDatabase
            val cursor = db.query(
                TABLE_BLOCKED_APPS,
                arrayOf(COLUMN_IS_BLOCKED),
                "$COLUMN_PACKAGE_NAME = ?",
                arrayOf(packageName),
                null, null, null
            )
            val isBlocked = cursor.use {
                it.moveToFirst() && it.getInt(0) == 1
            }
            isBlocked
        } catch (e: Exception) {
            Log.e(TAG, "Error checking if app is blocked: ${e.message}")
            false
        }
    }

    fun getAllBlockedApps(): List<String> {
        val blockedApps = mutableListOf<String>()
        try {
            val db = readableDatabase
            val cursor = db.query(
                TABLE_BLOCKED_APPS,
                arrayOf(COLUMN_PACKAGE_NAME),
                "$COLUMN_IS_BLOCKED = ?",
                arrayOf("1"),
                null, null, null
            )
            cursor.use {
                while (it.moveToNext()) {
                    blockedApps.add(it.getString(0))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting blocked apps: ${e.message}")
        }
        return blockedApps
    }

    fun clearAllBlockedApps(): Boolean {
        return try {
            val db = writableDatabase
            db.delete(TABLE_BLOCKED_APPS, null, null)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing blocked apps: ${e.message}")
            false
        }
    }
}