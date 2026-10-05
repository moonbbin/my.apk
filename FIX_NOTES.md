# 修复说明：播放 m3u8 报 ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED

## 问题原因

`app/src/main/java/com/tvbox/shell/player/PlayerActivity.kt` 里的
`createMediaSource()` 写死了 `ProgressiveMediaSource`，它只认 MP4/WebM
这类渐进式容器。采集站返回的 `.m3u8` 是 HLS 播放列表（文本），被它当成
视频文件去解析容器头，解析失败就抛
`ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED`，播放器显示"播放失败"。

## 代码修改（已改好）

`createMediaSource()` 改用 `DefaultMediaSourceFactory`，它会按 URL 后缀 /
Content-Type 自动选择 Progressive / HLS / DASH，不用再手动判断：

```kotlin
private fun createMediaSource(videoUrl: String, headers: Map<String, String>): MediaSource =
    DefaultMediaSourceFactory(PlayerDataSourceFactory.create(headers))
        .createMediaSource(MediaItem.fromUri(videoUrl))
```

## 你还需要手动加一步：补 HLS 依赖

`DefaultMediaSourceFactory` 播 m3u8 需要 `media3-exoplayer-hls` 在 classpath
上，否则 HLS 还是播不了。源码包里没有 gradle 文件，请在你自己工程的
`app/build.gradle.kts`（或 `build.gradle`）的 dependencies 里加一行，
版本号跟你项目里其它 media3 依赖保持一致：

```kotlin
// build.gradle.kts
implementation("androidx.media3:media3-exoplayer-hls:1.7.1")
```

```groovy
// build.gradle
implementation "androidx.media3:media3-exoplayer-hls:1.7.1"
```

加完后 Sync 一下，重新打包安装，m3u8 就能正常播了。
MP4 直链不受影响（DefaultMediaSourceFactory 同样能识别）。
