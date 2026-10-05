package com.tvbox.shell

/**
 * 版本信息。
 *
 * 约定：每改一次，[VERSION_CODE] +1，[VERSION_NAME] 的最后一位 +1，
 * 发出去的源码 zip 包名同步加一（如 tvbox-shell-v3.zip）。
 * 版本名展示在设置页最底部。
 */
object BuildInfo {

    /** 版本名。 */
    const val VERSION_NAME: String = "1.0.3"

    /** 版本号（每次改动 +1）。 */
    const val VERSION_CODE: Int = 3
}
