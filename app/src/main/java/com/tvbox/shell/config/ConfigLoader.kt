package com.tvbox.shell.config

import android.util.Log
import com.tvbox.shell.model.AppConfig
import com.tvbox.shell.model.Site
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/**
 * 配置加载器：把网上五花八门的"配置源"拉回来，统一成 [AppConfig]。
 *
 * 兼容的配置格式（按优先级）：
 * 1. `{"sites":[{key,name,type,api,ext}]}` —— 本工程标准格式；
 * 2. `{"videoSites":[…]}` / `{"list":[…]}` —— 别名；
 * 3. TVBox 官版格式：`{"sites":[{key,name,type,api,ext}]}` 同 1（字段名一致，可直接用）；
 * 4. 纯数组：`[{…},{…}]` —— 整份就是站点数组。
 *
 * 站点字段兼容：`api` / `ext` / `extString` 三种写法都认。
 * 拉不到 / 解析不出站点 → 返回空 [AppConfig]（调用方按"没有可用站点"处理，不抛）。
 */
object ConfigLoader {

    private const val TAG = "ConfigLoader"

    private val client: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(15, TimeUnit.SECONDS)
            .callTimeout(20, TimeUnit.SECONDS)
            .followRedirects(true)
            .build()
    }

    /** 拉一份配置。只允许在 IO 线程调（内部自己切 IO，调用方可直接调）。 */
    suspend fun loadConfig(url: String): AppConfig = withContext(Dispatchers.IO) {
        val clean = url.trim()
        if (!clean.startsWith("http", ignoreCase = true)) {
            Log.w(TAG, "配置地址不合法：$clean")
            return@withContext AppConfig()
        }
        try {
            val request = Request.Builder().url(clean)
                .header("User-Agent", UA).build()
            client.newCall(request).execute().use { resp ->
                if (!resp.isSuccessful) {
                    Log.w(TAG, "拉配置非 2xx：${resp.code} $clean")
                    return@withContext AppConfig()
                }
                val body = resp.body?.string().orEmpty()
                if (body.isBlank()) return@withContext AppConfig()
                parseConfig(body)
            }
        } catch (t: Throwable) {
            Log.w(TAG, "拉配置失败：${t.javaClass.simpleName}: ${t.message}")
            AppConfig()
        }
    }

    /** 解析配置 JSON（纯函数，可单测）。 */
    fun parseConfig(json: String): AppConfig {
        return try {
            val t = json.trim()
            if (t.startsWith("[")) {
                return AppConfig(sites = parseSiteArray(org.json.JSONArray(t)))
            }
            val root = JSONObject(t)
            val arr = root.optJSONArray("sites")
                ?: root.optJSONArray("videoSites")
                ?: root.optJSONArray("list")
                ?: return AppConfig()
            AppConfig(sites = parseSiteArray(arr))
        } catch (e: Throwable) {
            Log.w(TAG, "配置解析失败：${e.javaClass.simpleName}")
            AppConfig()
        }
    }

    private fun parseSiteArray(arr: org.json.JSONArray): List<Site> {
        return buildList {
            for (i in 0 until arr.length()) {
                val o = arr.optJSONObject(i) ?: continue
                val api = o.optString("api").trim()
                if (api.isEmpty()) continue
                add(
                    Site(
                        key = o.optString("key").trim().ifBlank { api },
                        name = o.optString("name").trim().ifBlank { api },
                        type = o.optInt("type", 3),
                        api = api,
                        extString = o.optString("extString")
                            .ifBlank { o.optString("ext") }.trim()
                    )
                )
            }
        }
    }

    private companion object {
        const val UA = "Mozilla/5.0 (Linux; Android 13; TVBoxShell/1.0)"
    }
}
