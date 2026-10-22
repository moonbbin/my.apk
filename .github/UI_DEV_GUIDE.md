# 播放页架构与开发保命规范 (UI_DEV_GUIDE)

核心宗旨：主干（Activity）只做组装，组件只做展示，底层（Manager）只管逻辑。

## 第一条：组件隔离铁律（单向数据流）

- 在独立 UI 组件（如 PlayerControlBar、PlayerCover）内部，直接修改全局状态或发起网络/底层控制请求。
- 组件内部只允许写 `onClick = { onNext()}` 等事件回调（Lambda 向上传递）。
- 组件所有依赖的数据，必须通过参数（Props）自上而下传入。组件内部不允许私藏业务 State（纯 UI 状态如动画进度除外）。

## 第二条：源码基线固化（告别"缝合怪"）

- 再去重放 13 号原稿 + 历史补丁堆的脚本流程。那个流程正式废弃。
- 将当前重构完毕的干净版 LxPlayerActivity.kt（1717 行版）及 5 个独立组件，固化为新一代的"基线原稿"。
- 后续所有修改，直接在基线上打补丁或全量覆盖，严禁再引入新的"多层嵌套重放"。

## 第三条：安全边界与黑盒防御

- 未拆离的"全屏歌词"模块（FullScreenLyric）视为黑盒。除非必须修 Bug，否则严禁触碰其内部滚动和同步算法。主 Activity 仅通过 `showFullLyric = true` 触发它。
- 任何涉及播放器底层（MediaPlayer、音频焦点、网络请求）的逻辑，必须收口在 LxPlayerManager 中，严禁散落在 UI 层。

## 第四条：全局主题适配（写死颜色是重罪）

- 在 UI 组件中写死十六进制颜色（如 `Color(0xFF...)`）。
- 所有颜色（包括背景、文字、图标、高亮），必须调用 `musicColors().xxx`。
- 备注：为了未来的"深空流光"主题，发现一处写死，清理一处。

## 第五条：补丁与重构操作规范（防爆炸指南）

- 编写任何修改脚本前，必须先对锚点特征串进行全局计数（assert count == 1）。
- 遇到需要切除的代码中间夹着其他逻辑（比如歌词预览的 Box 外面有收藏按钮），必须采取分段切除，严禁盲切整段。
- 任何涉及大段代码删除的补丁，必须带事后断言（调用点 == 1、旧特征串 == 0、文件括号差值 == 0）。
- 所有脚本必须支持幂等重入（跳过）；推 CI 前必须跑本地全链重放，并做切除-重构逐字比对 True。

## 第六条：新增功能的落位指引

- 加图标/按钮：去 PlayerControlBar.kt 或 PlayerTopBar.kt 找位置。
- 调封面动画：去 PlayerCover.kt 用 graphicsLayer 或 animate*AsState。
- 改进度条样式：去 PlayerProgressBar.kt 动 Canvas 或 Box。
- 加点击事件：在组件暴露 `onXxxClick: () -> Unit`，在 Activity 组装时实现具体逻辑（如跳转 Intent、弹窗等）。

---

## 落地决议（2026-10-22 用户拍板）

- 第一条存量纯化列为第六批（34v65）：PlayerControlBar 的 togglePlayPause/cycleMode/Toast/playMode 直读、PlayerProgressBar 的两处 seekTo、PlayerCover 的 _isDarkCover 死读，全部机械改为传参/回调；单独提交、单独验证，不与基线固化混提。
- 第二条分步走：先执行 B（开发基线固化——以 1717 行 + 5 组件为唯一锚点来源，CI 构建链一字不动）；C（新脚本全量拥有播放页文件 + 20/22/34 相关补丁逐个退役）明确择日单独排期，每退役一步验一次构建，严禁顺手实施。
- 第四条待议清单：PlayerProgressBar 轨道底色 `Color(0xFF535353)` 映射 `musicColors().sliderTrack` 会改变色值——2026-10-22 经色值对比审计后已裁定：维持写死，见文末《色彩豁免与特例》。

---

## 附则：色彩豁免与特例

- 进度条底轨（PlayerProgressBar.kt）：维持写死色 `Color(0xFF535353)`。因播放页属于强沉浸场景，全局动态轨道色在浅色主题下对比度不足。此处作为特例保留，确保进度条在深浅模式下均有可靠的视觉锚点。
- 播放键 / 封面描边：相关 `Color.White` 属于播放器专属设计常量，不纳入全局换肤逻辑。
