#!/bin/sh

RevisionNumber=$(git rev-list --count HEAD --no-merges)
GitCommitHash=$(git rev-parse --short HEAD)

#参数处理
while getopts "c:r" opt
do
case "$opt" in
c) development_mode="$OPTARG";; # 参数configuration：Release, PreRelease
r) release_package="true";;
\?)     # unknown flag
echo >&2 \
"usage: $0 [-c configuration:[Release, PreRelease] -r release_package>]"
exit 1;;
esac
done
shift `expr $OPTIND - 1`

source "../version.config"

if [[ "$release_package" == "true" ]]; then
  zipFile="MLDualRecordingIOS_V${MLDRS_VERSION}.zip"
else
  zipFile="MLDualRecordingIOS_V${MLDRS_VERSION}_${GitCommitHash}_B${RevisionNumber}.zip"
fi
dstDir="../Payload"
dstDocDir="$dstDir/doc"
dstSDKDir="$dstDir/sdk"
dstDemoDir="$dstDir/demo"
devGuide="../doc/迈聆 SDK for iOS 开发流程指南.md"
devGuidePdf="../doc/迈聆 SDK for iOS 开发流程指南.pdf"
apiGuide="../doc/迈聆SDK for iOS API说明.md"
apiGuidePdf="../doc/迈聆SDK for iOS API说明.pdf"

# 判断原始的 zip 文件是否存在，存在则删除
rm ../MLDualRecording*.zip

# 判断 ./Payload 目录是否存在，存在则删除
if [ -d "$dstDir" ]; then
  rm -rf "$dstDir"
fi

# 创建 ./Payload 目录
mkdir "$dstDir"
mkdir "$dstDocDir"
mkdir "$dstSDKDir"
mkdir "$dstDemoDir"

function checkCommandResult()
{
    if [ $1 -ne 0 ]; then
        exit $1
    fi
}

# 编译双录SDK framework
./build_framework.sh -c $development_mode
checkCommandResult $?

# 拷贝 ./Build/Framework/Products 目录下的所有 framework 到 ./Payload 目录下
cp -R "../Build/Framework/Products/"*.framework "$dstSDKDir"

# 拷贝 ./MLDualRecording/MLDualRecording/Lib 目录下的所有 framework 到 ./Payload 目录下
cp -R "../MLDualRecording/MLDualRecording/Lib/"*.framework "$dstSDKDir"

# 拷贝 cocoapods集成的framework
OLD_SOCKETIO_FRAMEWORK_PATH="../Pods/MLSocketIO-iOS/MLSocketIO_iOS.framework"

# 拷贝Framework到主工程目录
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
mv ../Build/Framework/Products/*_dSYM.zip "../MLDualRecordingIOS_V${MLDRS_VERSION}_dSYM.zip"
rm -rf "../Build"

# 压缩 ./Payload 目录
cd ..
curl -o "smartdualrecordiosdemo.zip" "https://artifactory.gz.cvte.cn/artifactory/mindlinker/client/dualrecording/ios/demo/release/20231023_192216_593f6fd/SmartDualRecordDemo.zip"
unzip "./smartdualrecordiosdemo.zip" -d "./Payload/demo"
rm "smartdualrecordiosdemo.zip"
curl -o "remotedualrecordiosdemo.zip" "https://artifactory.gz.cvte.cn/artifactory/mindlinker/client/dualrecording/ios/demo/release/20231023_085945_c8f5a7e/RemoteDualRecordingDemo.zip"
unzip "./remotedualrecordiosdemo.zip" -d "./Payload/demo"
rm "remotedualrecordiosdemo.zip"
cd ./Payload
zip -r "../$zipFile" ./*
