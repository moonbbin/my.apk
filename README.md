# 影视壳子 v3（com.tvbox.shell）

Android TV 影视壳应用源码。当前版本：**1.0.3**（版本信息见 `com.tvbox.shell.BuildInfo`，展示在设置页最底部）。

## 版本约定

每改一次，`VERSION_CODE` +1，`VERSION_NAME` 最后一位 +1。

## 功能概览

- 卡片式详情页
- CMS 多源适配（苹果 CMS JSON/XML）
- 解析 / WebView 嗅探引擎
- 播放器设置（弹幕、双播放内核）
- 主题切换 + 自定义背景
- 底部导航（首页 / 搜索 / 历史 / 设置）

## 注意

- 播放器需自行添加 `media3-exoplayer-hls` 依赖
- 需在 `AndroidManifest.xml` 中注册新增的 2 个 Activity
- 未经 Android SDK 编译验证
