package com.tvbox.shell.loader

import android.content.Context
import android.util.Log
import com.tvbox.shell.spider.Spider
import dalvik.system.DexClassLoader
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * 插件动态加载器：`filesDir/spiders/*.jar` → [DexClassLoader] → [Spider] 实例。
 *
 * 进程内唯一（TvBoxApp 建一次）：内部缓存着 DexClassLoader 与已加载实例，
 * 建两份会导致同一个插件类在两个 loader 里变成不同的 Class。
 *
 * 类名约定：优先读 jar 内 `assets/plugin.properties` 的 `mainClass`；
 * 没写就按 `com.github.catvod.spider.{simpleName}` 猜（CatVod 系插件打包规范）。
 */
class DexLoader(context: Context) {

    private val appContext = context.applicationContext ?: context
    private val spidersDir = File(appContext.filesDir, "spiders").apply { mkdirs() }
    private val optDir = File(appContext.filesDir, "spiders_opt").apply { mkdirs() }

    private val loaderCache = mutableMapOf<String, DexClassLoader>()
    private val instanceCache = mutableMapOf<String, Spider>()
    private val lock = Any()

    /** 插件目录（给 SpiderManager / 设置页"导入插件包"用）。 */
    fun dir(): File = spidersDir

    /** 有没有成功加载过任意插件（给站点排序用）。 */
    fun hasAnyPlugin(): Boolean = synchronized(lock) { instanceCache.isNotEmpty() }

    /**
     * 加载插件包里的 Spider。
     *
     * @param jarName 如 `csp_Kunyu.jar`
     * @param simpleName api 去掉 `csp_` 前缀的部分
     * @return 失败返回 null（原因打进 Logcat），不抛
     */
    fun loadSpider(jarName: String, simpleName: String): Spider? {
        synchronized(lock) {
            instanceCache[jarName]?.let { return it }
        }
        val jar = File(spidersDir, jarName)
        if (!jar.exists()) return null
        return try {
            val loader = synchronized(lock) {
                loaderCache.getOrPut(jarName) {
                    DexClassLoader(
                        jar.absolutePath,
                        optDir.absolutePath,
                        null,
                        appContext.classLoader
                    )
                }
            }
            val className = readMainClass(jar, loader)
                ?: "com.github.catvod.spider.$simpleName"
            val clazz = loader.loadClass(className)
            val spider = clazz.getDeclaredConstructor().newInstance() as? Spider
            if (spider == null) {
                Log.w(TAG, "$jarName 的 $className 不是 Spider 实现")
                return null
            }
            synchronized(lock) { instanceCache[jarName] = spider }
            Log.i(TAG, "插件加载成功：$jarName → $className")
            spider
        } catch (t: Throwable) {
            Log.w(TAG, "插件加载失败 $jarName：${t.javaClass.simpleName}: ${t.message}")
            null
        }
    }

    /**
     * 从 ext 地址下载插件包到 spiders 目录。
     *
     * @return 成功 true。下载是幂等的：文件已存在且非空就直接返回 true。
     */
    fun downloadPlugin(url: String, jarName: String): Boolean {
        val target = File(spidersDir, jarName)
        if (target.exists() && target.length() > 0) return true
        return try {
            val client = OkHttpClient.Builder()
                .connectTimeout(15, TimeUnit.SECONDS)
                .readTimeout(60, TimeUnit.SECONDS)
                .build()
            val request = Request.Builder().url(url)
                .header("User-Agent", UA).build()
            client.newCall(request).execute().use { resp ->
                if (!resp.isSuccessful) {
                    Log.w(TAG, "插件包下载失败：${resp.code} $url")
                    return false
                }
                val tmp = File(spidersDir, "$jarName.tmp")
                tmp.outputStream().use { out ->
                    resp.body?.byteStream()?.copyTo(out)
                }
                if (!tmp.renameTo(target)) {
                    tmp.delete()
                    return false
                }
                Log.i(TAG, "插件包下载成功：$jarName（${target.length()} 字节）")
                true
            }
        } catch (t: Throwable) {
            Log.w(TAG, "插件包下载异常：${t.javaClass.simpleName}: ${t.message}")
            false
        }
    }

    /** 读 jar 里 assets/plugin.properties 的 mainClass（没有就返回 null，外层按约定猜）。 */
    private fun readMainClass(jar: File, loader: DexClassLoader): String? {
        return try {
            loader.getResourceAsStream("assets/plugin.properties")?.use { ins ->
                val props = java.util.Properties()
                props.load(ins)
                props.getProperty("mainClass")?.trim()?.ifBlank { null }
            }
        } catch (t: Throwable) {
            null
        }
    }

    private companion object {
        const val TAG = "DexLoader"
        const val UA = "Mozilla/5.0 (Linux; Android 13; TVBoxShell/1.0)"
    }
}
