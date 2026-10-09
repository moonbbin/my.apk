package com.github.tvbox.osc.util

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.github.tvbox.osc.ui.activity.LxEngineHolder

/**
 * App 启动时自动预热音乐引擎（无需改 Application 类）
 * 延迟 3 秒，等 App 启动完成再预热，避免拖慢开机
 */
class LxEngineInitProvider : ContentProvider() {
    override fun onCreate(): Boolean {
        try {
            val appCtx = context?.applicationContext ?: return true
            Log.i("LxEngineInit", "App 启动，3 秒后后台预热音乐引擎")
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    LxEngineHolder.warmUp(appCtx)
                    Log.i("LxEngineInit", "后台预热已触发")
                } catch (e: Exception) {
                    Log.e("LxEngineInit", "后台预热失败", e)
                }
            }, 3000)
        } catch (e: Exception) {
            Log.e("LxEngineInit", "初始化失败", e)
        }
        return true
    }

    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor? = null
    override fun getType(uri: Uri): String? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int = 0
}
