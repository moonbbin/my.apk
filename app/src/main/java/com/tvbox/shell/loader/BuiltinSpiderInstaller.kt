package com.tvbox.shell.loader

import android.content.Context
import android.util.Log
import java.io.File

/**
 * 内置插件包安装器：`assets/spiders/*.jar` → `filesDir/spiders/`。
 *
 * 幂等：目标文件已存在且非空就跳过。复制用"写临时文件 + 原子改名"，
 * 不会出现半截文件被 DexClassLoader 读到的情况。
 */
class BuiltinSpiderInstaller(context: Context) {

    private val appContext = context.applicationContext ?: context

    /**
     * 释放内置插件包。
     *
     * @return 成功释放（或已存在）的文件数。assets 里没有 spiders 目录返回 0，不算错。
     */
    fun installBuiltinSpiders(): Int {
        val targetDir = File(appContext.filesDir, "spiders").apply { mkdirs() }
        val assets = try {
            appContext.assets.list("spiders") ?: emptyArray()
        } catch (t: Throwable) {
            Log.w(TAG, "assets/spiders 不可读：${t.javaClass.simpleName}")
            return 0
        }
        var count = 0
        for (name in assets) {
            if (!name.endsWith(".jar", ignoreCase = true)) continue
            val target = File(targetDir, name)
            if (target.exists() && target.length() > 0) {
                count++
                continue
            }
            try {
                appContext.assets.open("spiders/$name").use { ins ->
                    val tmp = File(targetDir, "$name.tmp")
                    tmp.outputStream().use { out -> ins.copyTo(out) }
                    if (tmp.renameTo(target)) {
                        count++
                        Log.d(TAG, "内置插件包已释放：$name")
                    } else {
                        tmp.delete()
                    }
                }
            } catch (t: Throwable) {
                Log.w(TAG, "释放 $name 失败：${t.javaClass.simpleName}")
            }
        }
        return count
    }

    private companion object {
        const val TAG = "BuiltinInstaller"
    }
}
