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
| 25 | `25_music_pages_wire.sh` | 四页面导航接线（排行/歌单/搜索/设置 → MusicHomeActivity）<br>glass1/glass2：设置卡+底栏玻璃化、底栏极简化。<br>itemcards（2026-10-24）：设置页去分组标题（音乐源/播放/显示），每项独立玻璃卡、删分割线、项间统一 12dp。 |
| 26 | `26_music_rank_polish.sh` | 排行榜精修（已并入 28，保留文件） |
| 27 | `27_music_playlist_cover.sh` | 歌单封面 |
| 28 | `28_music_rank_capsule.sh` | **排行榜胶囊精修**（当前迭代脚本）<br>榜单名胶囊、音质标签（橙色 QualityOrange，平台透传） |
| 29 | `29_music_rank_capsule_fix.sh` | 胶囊修复（历史，已跑过） |
| 30 | `30_music_rank_capsule_green.sh` | 胶囊绿色版（未被 build.yml 引用，内容已并入 28） |
| 31 | `31_music_search_result.sh` | **搜索二级结果页**<br>SearchResultScreen.kt + 接线到 LxMusicSearchActivity |
| 32 | `32_music_theme_dark_light.sh` | **深色/浅色主题切换**<br>三档（跟随系统/深色/浅色）存 theme_prefs；LxMusicTheme 桥接；独立 Activity 全量覆盖<br>v96（2026-10-24）：默认深色（theme_mode 未设置时 5 处读取默认 0→1，存量语义不变）+ 设置页「主题外观」入口改 Toast 开发中。<br>v97（2026-10-24）：底部 Tab 改悬浮胶囊——废 Scaffold bottomBar，迷你播放器+胶囊悬浮于根 Box 底部（Surface extraLarge + card 85% + shadowElevation 8），5 个 Canvas 线条图标（选中 accent+放大 1.15、无色块），设置/排行/歌单三页列表底部避让 104dp。<br>v98（2026-10-24 装机反馈瘦身）：胶囊总高锁定 56dp、圆角改 RoundedCornerShape(percent = 50) 真胶囊、背景改黑 50%/白 70% 毛玻璃（0.70f 写法避开 39 的 scrim 锚点）、阴影 4dp。<br>v99（2026-10-24）：迷你播放器单行瘦身（封面 24dp、歌名 13sp+歌手 11sp 单行标注串、按钮 28/24，总高约 36dp）；排行榜 FAB bottom 16→140dp 避让悬浮区。<br>v100（2026-10-24）：排行榜废 FAB+底部弹窗，改左侧边缘小尾巴（44×76、offset -22、cardSecondary 80%）+ 自定义 AnimatedVisibility 抽屉（264dp、内容为原切换列表整段平移、点遮罩/选完自动收回）。<br>v101（2026-10-24）：设置卡磨砂化（alpha 0.75→0.45、白边与 large 圆角本来就有）、卡间距 12→16dp、设置页底部避让 104→140dp（v97 只算了胶囊、漏了迷你播放器 36dp，最后一项会被压）。<br>v102（2026-10-24）：Haze 实时毛玻璃本体——gradle 加 dev.chrisbanes.haze:haze-blur:2.0.1（与工程 Compose 1.12.1/Kotlin 2.4.20 逐位对齐）、MusicHomeScreen 声明 rememberHazeState、胶囊改 clip+hazeBlur（半径 30、tint 黑/白 0.3）+ Surface 透明 + 白 0.2 高光描边、未选中 tint 深色改白 0.6。<br>v102fix（2026-10-24 首建实测）：tint 不是 style 域函数——改 colorEffects(listOf(HazeColorEffect.tint(...)))（HazeColorEffect 伴生工厂）。<br>v102fix2（2026-10-24 装机无模糊→HazeEffectNode 源码实证）：Behind 入选条件 zIndex<祖先源 zIndex，根 Box 既是唯一源又是祖先源恒假→无源只剩 scrim；input 改 HazeSourceSelection.All。<br>v102fix3（2026-10-24 装机闪退实证：All 会采祖先源、被 HazeEffectNode 的 require 禁止）：input 回 Behind 默认；页内容 when 外包同级 hazeSource Box 作源（与胶囊同级非祖先）。<br>v103（2026-10-24）：Haze 参数动态绑定——blurRadius/tint 改读 WallpaperManager 的 hazeRadius/hazeTint（壁纸设置页滑杆调节，39 haze3 数据层配套）；半径 0 时 tint 自动兜底 0.8f。<br>v104（2026-10-24 毛玻璃独立化，用户定"按组件单独调节"）：新建 ui/music/glass/GlassSettings.kt（glass_prefs 按组件分组，每组 enabled/radius/tint；含 v103 旧值一次性迁移）；胶囊改读 GlassSettings.capsule，enabled=false 时不挂 hazeBlur、Surface 回 v98 纯色（黑 0.5/白 0.70）；设置页（SettingsScreen）底部加独立卡 GlassCapsuleCard（Switch+双滑杆，松手写盘）；MH 的 wpState.haze* 引用清零。<br>v105（2026-10-24 高级质感）：GlassSettings capsule 组加 border（边缘反光 0–50%，默认 20）/shadow（悬浮高度 0–20dp，默认 4）两字段+setter，无旧键时默认值=现行视觉零突变；MH 胶囊 BorderStroke alpha 与 Surface shadowElevation 改动态读；设置卡在玻璃开关内加「边缘反光/悬浮高度」两滑杆（松手写盘）。 |
| 34 | `34_player_immersive.sh` | 播放页沉浸式迭代（已退役）<br>v1–v65 全部成果（含五组件抽离与纯化）已固化进 35 号基线；2026-10-22 build.yml 调用步已删除，文件保留备查。 |
| 35 | `35_player_baseline.sh` | **播放页基线原稿（现行唯一所有者）**<br>base64 全量写入播放页 7 文件：LxPlayerActivity.kt（1724 行）+ PlayerControls/PlayerTopBar/PlayerProgressBar/PlayerCover/PlayerLyricPreview + LxIcons.kt；内容与开发基线同步；build.yml 末位运行。今后改播放页先改基线再重生本脚本载荷。 |

## 歌单 / 均衡器 / 壁纸（36-39）

| # | 脚本 | 干嘛的 |
|---|------|--------|
| 36 | `36_user_playlist.sh` | **自建歌单**<br>UserPlaylistManager（SharedPreferences 落盘）+ 歌单页；含 QQ/酷狗歌单导入支持。<br>pill（2026-10-24）：UserPlaylistScreen 列表底部避让悬浮胶囊 104dp。 |
| 37 | `37_eq_settings.sh` | **均衡器设置页**<br>两页 Pager（PEQ 六段 + 六级 DSP 开关），播放页以 Dialog 悬浮呈现。 |
| 38 | `38_eq_dsp.sh` | **自研 DSP 引擎**<br>六级独立开关：PEQ/联动拓宽/四段 MBC/Sub 合成/瞬态/Crossfeed；现行参数 = v14 回滚的稳妥档（v12 参数)。 |
| 39 | `39_wallpaper.sh` | **自定义壁纸**<br>wp1：WallpaperManager（图片模式）+ 设置页 + MusicHome 根注入（壁纸层+Scrim）+ 六页根透出（alpha04 装机验证通过）。<br>wp2：渐变模式（Manager mode/gradient 双字段 + 三预设）+ 在线壁纸库（当时 picsum Mock 占位）。<br>wp3：壁纸库换真实源——搜图神器聚合图池（签名协议已逆向：time 扰动 + 全参排序 MD5，8 分类：精选/高清/全面屏/2K/4K/AI绘画/平板/聊天背景，实测 code=200）；加载更多分页 + 按 id 去重。<br>wp4：效果调整（参考 Peek 壁纸设置）——文字颜色模式（跟随主题/浅色文字/深色文字，经 MH 的 effDark41 接入 32 同步点，状态栏图标同步）+ 遮罩浓度滑杆（0–90%，未动时自动沿用深 60/浅 70）；不透明度/模糊暂缓。<br>wp5（现行）：装机反馈两问题修复——文字模式回滚主题钩子，改 MH 子树 LocalMusicColors 覆盖（方案 B：文字四件+卡片两面，accent/主题/状态栏不动，设置页/播放页不翻）；遮罩纱色跟文字模式走；补齐 Peek 三件：不透明度（默认 100%）+ 模糊（Coil3 预模糊 WpBlurTransformation，默认 0）；搜索框玻璃化（壁纸开启时容器 55% 半透明）。<br>fix3：模糊改三轮盒式近似高斯（对齐 Peek ImageFilter sigma 语义，弃缩图像素化）。<br>fix4：不透明度加合成底（壁纸层先刷 musicColors().background，照片溶进页面底色而非透窗口底）+ 滑杆放开 0–100%。<br>fix5：遮罩对齐 Peek darkOverlay——纯黑单色 + 默认 0 无纱（删自动黑 60/白 70 与白纱分支，存量 -1 归 0）；wp5 区守卫改 wpBaseBg。<br>fix6：文字模式只对应文字四件（textPrimary/textSecondary/textHint/iconTint），卡片 card/cardSecondary 不再跟随翻色（对齐 Peek「文字颜色模式」本义）。<br>haze（2026-10-24）：根 Box 挂 .hazeSource(hazeState) 作 Haze 采样源（state 由 32 v102 声明）。<br>haze2（2026-10-24 拓扑修正）：根 Box 撤销作源，改壁纸层（wpActive 内包 Box）挂 hazeSource，与 32fix3 的页内容源并列、均与胶囊同级。<br>haze3（2026-10-24）：WallpaperManager 加 hazeRadius（0–50，默认 30）/hazeTint（0–80%，默认 30）两字段+setter（wallpaper_prefs 落盘）；壁纸设置页新增「导航胶囊 · 毛玻璃」卡（两滑杆，onValueChangeFinished 才写盘，拖动只动本地状态）。<br>haze3 已撤销（v104 独立化）：Manager 的 haze 两字段/setter 与壁纸页毛玻璃卡全部移除（壁纸侧零 haze 残留）；新增 [39glass] 段：MH 补 GlassSettings import 并在 LaunchedEffect 里接 GlassSettings.init(context)。|

## 约束速查

- **不动主体**：只改 `.github/scripts`，不改 AVBox 源码；`.github/workflows/build.yml` 由用户在网页端手动改（App 无 workflows 权限）。
- **UI 规范**：颜色/圆角/字号一律走全局主题 Token，不写死 Hex。
- **脚本数量**：同功能迭代改原脚本，不新增；全新功能才建新脚本。
- **幂等**：每个脚本必须支持全新构建 + 增量升级 + 重复运行跳过；锚点未命中要大声失败（exit 1），不静默跳过。
- **13 号红线**：`13_music_player.sh` 是 48KB base64+gzip，绝不重写；改播放器走 21/22 补丁。
