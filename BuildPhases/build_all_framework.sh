#!/bin/sh

RevisionNumber=$(git rev-list --count HEAD --no-merges)
GitCommitHash=$(git rev-parse --short HEAD)

#参数处理
while getopts "c:s:e:p" opt
do
case "$opt" in
c) development_mode="$OPTARG";; # 参数configuration：Release, Debug, PreRelease
s) opt_sdk_version="$OPTARG";;
e) sdk_env="$OPTARG";;
\?)     # unknown flag
echo >&2 \
"usage: $0 [-c configuration -s sdk_version -e sdk_environment -p pod_update>]"
exit 1;;
esac
done
shift `expr $OPTIND - 1`

source "../version.config"

zipFile="MLDualRecordingSDKiOS_V${MLDRS_VERSION}_${GitCommitHash}_B${RevisionNumber}.zip"
dstDir="../Payload"
dstDocDir="$dstDir/doc"
dstSDKDir="$dstDir/sdk"
devGuide="../doc/迈聆 SDK for iOS 开发流程指南.md"
devGuidePdf="../doc/迈聆 SDK for iOS 开发流程指南.pdf"
apiGuide="../doc/迈聆SDK for iOS API说明.md"
apiGuidePdf="../doc/迈聆SDK for iOS API说明.pdf"

# 判断原始的 zip 文件是否存在，存在则删除
rm ../MLDualRecording*.zip
# if [ -f "$zipFile" ]; then
#   rm "$zipFile"
# fi

# 判断 ./Payload 目录是否存在，存在则删除
if [ -d "$dstDir" ]; then
  rm -rf "$dstDir"
fi

# 创建 ./Payload 目录
mkdir "$dstDir"
mkdir "$dstDocDir"
mkdir "$dstSDKDir"

# 编译双录SDK framework
./build_framework.sh -c $development_mode -s "${opt_sdk_version}" -e "${sdk_env}"

# 拷贝 ./Build/Framework/Products 目录下的所有 framework 到 ./Payload 目录下
cp -R "../Build/Framework/Products/"*.framework "$dstSDKDir"

# 拷贝 ./MLDualRecording/MLDualRecording/Lib 目录下的所有 framework 到 ./Payload 目录下
cp -R "../MLDualRecording/MLDualRecording/Lib/"*.framework "$dstSDKDir"

# 拷贝 cocoapods集成的framework
OLD_RTMQBASE_FRAMEWORK_PATH="../Pods/RtmqIM/cocoa/iOS/RtmqBaseSDK.framework"
OLD_RTMQIM_FRAMEWORK_PATH="../Pods/RtmqIM/cocoa/iOS/RtmqIMSDK.framework"
OLD_SOCKETIO_FRAMEWORK_PATH="../Pods/MLSocketIO-iOS/MLSocketIO_iOS.framework"

# 拷贝Framework到主工程目录
cp -R "$OLD_RTMQBASE_FRAMEWORK_PATH" "$dstSDKDir"
cp -R "$OLD_RTMQIM_FRAMEWORK_PATH" "$dstSDKDir"
cp -R "$OLD_SOCKETIO_FRAMEWORK_PATH" "$dstSDKDir"

# 使用md文档生成pdf文档
# npm install mdpdf --save
# alias mdpdf=./node_modules/.bin/mdpdf
# 开发指南
mdpdf "$devGuide"
cp "$devGuidePdf" "$dstDocDir"
rm "$devGuidePdf"
# API文档
mdpdf "$apiGuide"
cp "$apiGuidePdf" "$dstDocDir"
rm "$apiGuidePdf"

# 拷贝SDK包README文档
cp "../doc/README.md" "$dstDir"
cp "../doc/Demo下载.jpg" "$dstDir"

# 压缩 ./Payload 目录
cd ../Payload
zip -r "../$zipFile" ./*
