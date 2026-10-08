#!/bin/bash
set -e
cd avbox
sed -i 's/AVBox/清风/g' app/src/main/res/values/strings.xml
sed -i 's/applicationId = "com.github.avbox.osc"/applicationId = "com.qingfeng.tvbox"/' app/build.gradle.kts
sed -i 's/AVBox_/qingfeng_/g' app/build.gradle.kts
