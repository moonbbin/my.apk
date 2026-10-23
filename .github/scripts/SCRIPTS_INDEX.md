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
| 20 | `20_music_theme.sh` | 全局主题定稿（Color.kt/Type.kt/Theme.kt）<br>定义所有 Token：颜色、圆角、字号。页面 UI 只准用 Token，不准写死 Hex。<br>2026-10-22 C 结案：已删除 LxPlayerActivity 的 PATCHES 条目，不再触碰播放页（仍处理搜索/歌手/主页/历史 4 文件）。 |
| 23 | `23_music_theme_unify.sh` | 主题统一：补 TextOnAccent/SliderTrack 常量；DarkMusicColors 全改引 Token |

## 音质验货与显示（21/22）⚠️ 核心

| # | 脚本 | 干嘛的 |
|---|------|--------|
| 21 | `21_music_bitrate_guard.sh` | **播放器音质验货（防糊）**<br>补丁目标：`LxPlayerManager.kt`（13 生成）<br>版本历史见脚本头部 v1→v10 导航注释。<br>关键锚点：`QUALITY_ORDER`（请求顺序）、`tierOfQuality()`（档位映射）、`verifyQuality()`（验货入口） |
| 22 | `22_music_bitrate_display.sh` | **播放页音质徽标**（已退役）<br>2026-10-22 C 结案：徽标已固化进 35 号基线，build.yml 调用步已删除，文件保留备查。 |

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

**21 v19：** 切歌清空 `_currentQuality`/`_measuredBitrate`/`_bitrate`（防旧徽标残留）

### 32 版本速查（主题切换）

**32（主题）：**
- v1-v12：基础建设（Build #244 OK）
- v13/v14：红构建（Hilt/错文件）；v20 越界改 MainActivity（回滚）
- v26：MainActivity 从上游恢复（主体修复关闭）
- v30：三档切换 UI（theme_prefs + MusicThemeManager）
- v35-v55：背景/导航/TopAppBar 换 musicColors()；LxMusicTheme 桥接；onCreate 预设
- v56：暴力替换 colorScheme→musicColors()（Build #290 OK，误伤 scrim）
- v57-v71：精准修复（PlaylistScreen/ RankScreen/ Source/ Theme/ Artist/ Search）；Overlay 常量；badge 白字
- v72：5 二级页面统一（LxMusicTheme+状态栏+背景）
- v73-v75：HistoryActivity 正则失败（根因：构建机用 QingfengMusicTheme）
- v76：History 方案A全量覆盖（132 行 cat）
- v77/v78：删 v72/v73 的 History 正则死代码
- v79-v83：修 Conflicting declarations + Card(color=) 误用（5 版试错）
- v84/v85：Playback 方案A全量覆盖（删 bgFollowCover，因 v33 已删该方法）
- v86：清死代码（删 673 行 v72/v75/v79-v84）；Quality/Lyric/Favorites/ThemeSettings 方案A全量覆盖

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
| 32 | `32_music_theme_dark_light.sh` | **深色/浅色主题切换**<br>三档（跟随系统/深色/浅色）存 theme_prefs；LxMusicTheme 桥接；独立 Activity 全量覆盖 |
| 34 | `34_player_immersive.sh` | 播放页沉浸式迭代（已退役）<br>v1–v65 全部成果（含五组件抽离与纯化）已固化进 35 号基线；2026-10-22 build.yml 调用步已删除，文件保留备查。 |
| 35 | `35_player_baseline.sh` | **播放页基线原稿（现行唯一所有者）**<br>base64 全量写入播放页 7 文件：LxPlayerActivity.kt（1724 行）+ PlayerControls/PlayerTopBar/PlayerProgressBar/PlayerCover/PlayerLyricPreview + LxIcons.kt；内容与开发基线同步；build.yml 末位运行。今后改播放页先改基线再重生本脚本载荷。 |

## 歌单 / 均衡器 / 壁纸（36-39）

| # | 脚本 | 干嘛的 |
|---|------|--------|
| 36 | `36_user_playlist.sh` | **自建歌单**<br>UserPlaylistManager（SharedPreferences 落盘）+ 歌单页；含 QQ/酷狗歌单导入支持。 |
| 37 | `37_eq_settings.sh` | **均衡器设置页**<br>两页 Pager（PEQ 六段 + 六级 DSP 开关），播放页以 Dialog 悬浮呈现。 |
| 38 | `38_eq_dsp.sh` | **自研 DSP 引擎**<br>六级独立开关：PEQ/联动拓宽/四段 MBC/Sub 合成/瞬态/Crossfeed；现行参数 = v14 回滚的稳妥档（v12 参数)。 |
| 39 | `39_wallpaper.sh` | **自定义壁纸**<br>wp1：WallpaperManager（图片模式）+ 设置页 + MusicHome 根注入（壁纸层+Scrim）+ 六页根透出（alpha04 装机验证通过）。<br>wp2：渐变模式（Manager mode/gradient 双字段 + 三预设）+ 在线壁纸库（当时 picsum Mock 占位）。<br>wp3：壁纸库换真实源——搜图神器聚合图池（签名协议已逆向：time 扰动 + 全参排序 MD5，8 分类：精选/高清/全面屏/2K/4K/AI绘画/平板/聊天背景，实测 code=200）；加载更多分页 + 按 id 去重。<br>wp4：效果调整（参考 Peek 壁纸设置）——文字颜色模式（跟随主题/浅色文字/深色文字，经 MH 的 effDark41 接入 32 同步点，状态栏图标同步）+ 遮罩浓度滑杆（0–90%，未动时自动沿用深 60/浅 70）；不透明度/模糊暂缓。<br>wp5（现行）：装机反馈两问题修复——文字模式回滚主题钩子，改 MH 子树 LocalMusicColors 覆盖（方案 B：文字四件+卡片两面，accent/主题/状态栏不动，设置页/播放页不翻）；遮罩纱色跟文字模式走；补齐 Peek 三件：不透明度（默认 100%）+ 模糊（Coil3 预模糊 WpBlurTransformation，默认 0）；搜索框玻璃化（壁纸开启时容器 55% 半透明）。<br>fix3：模糊改三轮盒式近似高斯（对齐 Peek ImageFilter sigma 语义，弃缩图像素化）。<br>fix4：不透明度加合成底（壁纸层先刷 musicColors().background，照片溶进页面底色而非透窗口底）+ 滑杆放开 0–100%。 |

## 约束速查

- **不动主体**：只改 `.github/scripts`，不改 AVBox 源码；`.github/workflows/build.yml` 由用户在网页端手动改（App 无 workflows 权限）。
- **UI 规范**：颜色/圆角/字号一律走全局主题 Token，不写死 Hex。
- **脚本数量**：同功能迭代改原脚本，不新增；全新功能才建新脚本。
- **幂等**：每个脚本必须支持全新构建 + 增量升级 + 重复运行跳过；锚点未命中要大声失败（exit 1），不静默跳过。
- **13 号红线**：`13_music_player.sh` 是 48KB base64+gzip，绝不重写；改播放器走 21/22 补丁。
