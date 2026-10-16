# .github/scripts 脚本索引

> 构建期补丁脚本一览。按执行顺序排列（对应 build.yml 调用顺序）。
> 每个脚本只做一件事；同功能迭代就地改脚本，不新增。
> 详细版本历史见各脚本头部注释。

## 基础构建（00-10）

| # | 脚本 | 干嘛的 |
|---|------|--------|
| 00 | `00_version.sh` | 写入版本号 |
| 01 | `01_branding.sh` | 品牌信息（应用名等） |
| 02 | `02_settings_appname.sh` | 设置页应用名 |
| 03 | `03_cat_avatar.sh` | 猫头头像资源 |
| 04 | `04_home_icon.sh` | 首页图标 |
| 05 | `05_music_tab.sh` | 音乐 Tab 入口（05→11→12→13→14→15→16→17 为音乐能力链） |
| 06 | `06_icons.sh` | 图标资源 |
| 07 | `07_keystore.sh` | 签名配置 |
| 09 | `09_appicon.sh` | 应用图标 |
| 10 | `10_splash_icon.sh` | 启动图图标 |

## 音乐引擎与播放器（11-19）

| # | 脚本 | 干嘛的 |
|---|------|--------|
| 11 | `11_music_engine.sh` | 洛雪 JS 引擎（LxMusic 脚本沙箱） |
| 12 | `12_music_ui.sh` | 音乐 UI 基础 |
| 13 | `13_music_player.sh` | 播放器（ExoPlayer，48KB base64+gzip，**勿重写**）<br>生成 `LxPlayerActivity.kt` + `LxPlayerManager.kt` |
| 14 | `14_music_search.sh` | 搜索功能 |
| 15 | `15_music_home.sh` | 音乐首页（MusicHomeActivity，5 个 Tab 导航） |
| 16 | `16_music_startup.sh` | 启动逻辑 |
| 17 | `17_music_cover.sh` | 封面（Coil 加载） |
| 18 | `18_music_player_spotufi.sh` | Spotify 风格播放器（与 13 互斥，当前未启用） |
| 19 | `19_pyramid_pip_retry.sh` | 画中画重试 |

## 主题（20/23）

| # | 脚本 | 干嘛的 |
|---|------|--------|
| 20 | `20_music_theme.sh` | 全局主题定稿（Color.kt/Type.kt/Theme.kt）<br>定义所有 Token：颜色、圆角、字号。页面 UI 只准用 Token，不准写死 Hex。 |
| 23 | `23_music_theme_unify.sh` | 主题统一：补 TextOnAccent/SliderTrack 常量；DarkMusicColors 全改引 Token |

## 音质验货与显示（21/22）⚠️ 核心

| # | 脚本 | 干嘛的 |
|---|------|--------|
| 21 | `21_music_bitrate_guard.sh` | **播放器音质验货（防糊）**<br>补丁目标：`LxPlayerManager.kt`（13 生成）<br>版本历史见脚本头部 v1→v10 导航注释。<br>关键锚点：`QUALITY_ORDER`（请求顺序）、`tierOfQuality()`（档位映射）、`verifyQuality()`（验货入口） |
| 22 | `22_music_bitrate_display.sh` | **播放页音质徽标**<br>补丁目标：`LxPlayerActivity.kt`（13 生成）<br>实测码率优先显示；假无损标 ⚠；v6 起中文标签（母带/全景声+/全景声/Hi-Res） |

### 21/22 版本速查

**21（验货）：**
- v1-v3：基础验货、档位标签、FLAC 码率估算、假无损降档
- v4：`isSuspiciousLossless()`（死代码，22 已内联）
- v5-v6：Hi-Res 档位识别 → 7 档全映射（6=母带/5=全景声+/4=全景声/3=Hi-Res/2=FLAC/1=320k/0=普通）
- v7-v8：尝试改请求顺序（未命中真实格式，未生效）
- v9：解码 13 确认锚点 `QUALITY_ORDER`，精确替换为 master 优先（生效）
- v10：`getPreferredQuality()` 默认值改 master（生效）

**22（徽标）：**
- v1-v2：实测码率优先显示
- v4-v4.2：⚠ 自诊断（内联判断，不静态调用）
- v5-v6：Hi-Res 可疑检测 + 中文标签

## 页面 UI（24-31）

| # | 脚本 | 干嘛的 |
|---|------|--------|
| 24 | `24_music_rank_screen.sh` | 排行榜页 RankScreen.kt 写入 |
| 25 | `25_music_pages_wire.sh` | 四页面导航接线（排行/歌单/搜索/设置 → MusicHomeActivity） |
| 26 | `26_music_rank_polish.sh` | 排行榜精修（已并入 28，保留文件） |
| 27 | `27_music_playlist_cover.sh` | 歌单封面 |
| 28 | `28_music_rank_capsule.sh` | **排行榜胶囊精修**（当前迭代脚本）<br>榜单名胶囊、音质标签（橙色 QualityOrange，平台透传） |
| 29 | `29_music_rank_capsule_fix.sh` | 胶囊修复（历史，已跑过） |
| 30 | `30_music_rank_capsule_green.sh` | 胶囊绿色版（未被 build.yml 引用，内容已并入 28） |
| 31 | `31_music_search_result.sh` | **搜索二级结果页**<br>SearchResultScreen.kt + 接线到 LxMusicSearchActivity |

## 约束速查

- **不动主体**：只改 `.github/scripts`，不改 AVBox 源码；`.github/workflows/build.yml` 由用户在网页端手动改（App 无 workflows 权限）。
- **UI 规范**：颜色/圆角/字号一律走全局主题 Token，不写死 Hex。
- **脚本数量**：同功能迭代改原脚本，不新增；全新功能才建新脚本。
- **幂等**：每个脚本必须支持全新构建 + 增量升级 + 重复运行跳过；锚点未命中要大声失败（exit 1），不静默跳过。
- **13 号红线**：`13_music_player.sh` 是 48KB base64+gzip，绝不重写；改播放器走 21/22 补丁。
