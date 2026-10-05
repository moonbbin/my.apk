# 更新说明

## v3（2026-10-05）：底部导航 + 版本号机制

- 首页新增底部导航栏（首页 / 搜索 / 历史 / 设置），搜索和历史从全屏浮层改为 Tab 页，
  顶栏精简为标题 + 刷新；搜索/历史页背景透明化；测试同步更新。
- 新增版本机制：`com.tvbox.shell.BuildInfo`（VERSION_NAME/VERSION_CODE），
  设置页底部展示版本号；**以后每改一次，版本号 +1，源码 zip 包名同步 +1**。

## v2（2026-10-05）：5 个需求 + 缺失模块补齐 + 播放器 m3u8 修复

## 一、先说最重要的：源码包缺了 20 多个类，已按调用关系补齐

你上次发的 `tvbox-shell-interaction-module_1_zh9l.zip` 只是 interaction 模块，
被引用的 `model / parser / config / loader / spider / ui` 等包里的类都不在，
原样是编不过的。这次按现有代码的调用方式（HomeViewModel、测试替身等）
把缺失部分补齐了，补齐的文件都在下面"新增文件"里标了。
引擎细节（插件加载、采集解析）按常规实现（苹果 CMS JSON/XML、CatVod 插件规范）写的，
跟你原来的模块对得上就直接用，对不上就把对应文件换回你自己的。

## 二、5 个需求的实现

### 需求1：详情页卡片式排版
- `ui/detail/DetailScreen.kt` 重写：纵向 LazyColumn，四张 Card——
**简介卡**（封面+片名+评分/年份/地区/类型+主演/导演+可展开简介）、
**播放源卡**（多源 FilterChip，单源不显示）、
**剧集卡**（4 列剧集，点选高亮保留）、
**相关推荐卡**（横向封面流，点封面通过 `onVodClick` 回调）。
- 推荐数据走 `DetailViewModel.recommendFlow`（按分类/片名搜同类，失败不影响主体）。

### 需求2：多影视源接口适配
- 新增 `spider/CmsSpider.kt`：站点 `api` 直接写 `http…` 地址就走它，
不需要插件包。兼容苹果 CMS JSON（`/api.php/provide/vod/`）和老 CMS 的
XML（rss），字段别名由 `HomeContentParser` 兼容（vod_name/name/title 等）。
- `SpiderManager.resolveSpider` 路由：`http`→CMS 直连；`csp_Demo`→示范引擎；
`csp_xxx`→插件 jar；都拿不到→`SpiderNull`（调用方原有判断不变）。

### 需求3：网盘 / 解析 / m3u8 / 腾讯爱奇艺
- m3u8：上次已修（`DefaultMediaSourceFactory`，记得加 `media3-exoplayer-hls` 依赖）。
- 新增 `parse/ParseManager.kt`：解析链——直链直播 → 网盘分享/站内页标记嗅探 →
用户配的解析接口逐个试（JSON / 302 跳转）→ 兜底嗅探。
- 新增 `parse/ParseApi.kt`：解析接口配置（名称+地址+类型），设置页可增删。
- 新增 `parse/WebSniffActivity.kt`：WebView 嗅探页，打开网盘分享页/腾讯/爱奇艺等
站内页，拦截 `.m3u8/.mp4` 请求，抓到就跳播放器。30 秒超时自动退出。
- 详情页点播链路（`DetailViewModel.onPlayEpisode`）已接入：直链→引擎
playerContent→解析接口→嗅探（`PlayState.Sniff`）。
- 实话：网盘 OAuth 接入和腾讯/爱奇艺的加密流不在本次范围，走的是嗅探方案，
能抓到明文流就能播，抓不到会提示换源。

### 需求4：播放器设置
- 设置页（`ui/settings/SettingsActivity.kt`，首页右上角齿轮 / 播放器控制条齿轮进入）：
弹幕开关、弹幕颜色（6 色）、弹幕字号（0.5~2.5 倍）、弹幕源 API（`{keyword}` 模板）、
播放器内核切换（ExoPlayer / 系统播放器）。
- 弹幕：`player/DanmakuOverlay.kt`，按播放进度滚动，5 行轮转，暂停/seek 自动同步。
- 切换播放器：`player/PlayerUiState.kt` 抽象 + `ExoPlayerUiState` /
`SystemPlayerUiState(VideoView)` 两种实现，自绘控制条不动，设置里切换后下次进
播放页生效。

### 需求5：主题切换 + 自定义背景
- `ui/ShellTheme.kt`：主题模式（跟随系统/浅色/深色）+ 自定义背景
（无/纯色/图片，图片支持**网络 URL**和本地路径，自动压暗保证文字可读）。
- 首页、详情页、设置页已包进 `ShellTheme`，设置页改完即时预览；
其他页面想跟进，只需在最外层包一层 `ShellTheme {}`。
- 背景图片走自研 `AppImageLoader`（OkHttp+内存缓存），不引入 Coil。

## 三、你需要手动做的事（源码包里没有这些文件）

1. **加 HLS 依赖**（播 m3u8 必需），`app/build.gradle`：
`implementation "androidx.media3:media3-exoplayer-hls:<与你其他 media3 同版本>"`
2. **AndroidManifest.xml 注册两个新 Activity**：
```xml
<activity android:name=".ui.settings.SettingsActivity" android:exported="false" />
<activity android:name=".parse.WebSniffActivity" android:exported="false" />
```
3. 想开箱有片：`config/BuiltinSitesProvider.kt` 的 `defaultSources()` 里
把示例 CMS 地址换成你自己的接口（`api` 写 `http…` 即可走直连，不用插件包）。

## 四、新增文件清单

`model/Site.kt`（Site/AppConfig/Vod）、`parser/Episode.kt`
（Episode/EpisodeGroup/HomeCategory/HomeContentParser，含详情/播放地址解析）、
`spider/Spider.kt`、`spider/SpiderNull.kt`、`spider/SpiderProbe.kt`、
`spider/SpiderManager.kt`、`spider/DemoSpider.kt`、`loader/DexLoader.kt`、
`loader/BuiltinSpiderInstaller.kt`、`config/SiteSource.kt`、
`config/AppConfigManager.kt`、`config/SiteRepository.kt`、
`config/ConfigLoader.kt`、`config/SourceRestorer.kt`、
`config/BuiltinSitesProvider.kt`、`ui/ShellTheme.kt`、
`ui/component/AppImage.kt`（AppImageLoader/NetworkImage/RemotePoster）、
`player/PlayerViewModel.kt`、`ui/detail/DetailViewModel.kt`
（含 PlayState/DetailLoadState）、测试 `TestablePlayerActivity.kt`。

`spider/CmsSpider.kt`、`parse/ParseApi.kt`、`parse/ParseManager.kt`、
`parse/WebSniffActivity.kt`、`player/PlayerUiState.kt`、
`player/SystemPlayerUiState.kt`、`player/DanmakuOverlay.kt`、
`ui/settings/SettingsActivity.kt`。

## 五、修改的文件

- `player/PlayerActivity.kt`：m3u8 修复（DefaultMediaSourceFactory）；
双内核分支；控制条接 `PlayerUiState`；弹幕层；设置齿轮入口。
- `config/UserPreference.kt`：新增播放器/主题/解析接口三组偏好（含响应式 Flow）。
- `ui/detail/DetailScreen.kt`：卡片式重写（见需求1）。
- `ui/home/HomeScreen.kt`：包 `ShellTheme`；Scaffold 背景透明化；右上角设置按钮。

## 六、没做的（实话）

- 本机无 Android SDK/Gradle，**没编译验证**——所有文件只做了括号配平和
API 交叉检查，务必在 Android Studio 里完整编译一次，有报错贴给我修。
- 真机播放、嗅探成功率、插件 jar 加载这三条链路需要在真机上验证。
