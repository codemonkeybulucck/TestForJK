#!/bin/sh

BUILDPACKAGE_STARTTIME=$(date +%s)
BUILDPACKAGE_DATETIME=$(date +%Y%m%d)
PGY_API_KEY="9c59270b92aaf6ca77c27ba37f031be6"
IPA_PATH=""
RevisionNumber=$(git rev-list --count HEAD --no-merges)
SDK_BUILD=$(git rev-parse --short HEAD)
BUILD_CONFIGURATION="Debug"
SCHEME="TestForJK"
TEMP=$1
if [[ $TEMP == "clean" ]]; then
    CLEAN="clean"
    shift
fi

#参数处理
while getopts "c:u:p:r" opt
do
case "$opt" in
c) BUILD_CONFIGURATION="$OPTARG";; # 参数configuration：Release, Debug, PreRelease
u) UPLOAD_PGY="$OPTARG";;
p) UPDATE_POD="true";;
r) RELEASE_PACKAGE="true";;
\?)     # unknown flag
echo >&2 \
"usage: $0 [-c configuration -p pod_update -u upload_pgy -r release_package>]"
exit 1;;
esac
done
shift `expr $OPTIND - 1`

if [[ "$BUILD_CONFIGURATION" == "Release" || "$BUILD_CONFIGURATION" == "Debug" || "$BUILD_CONFIGURATION" == "PreRelease" ]]; then
    echo "build configuration : $BUILD_CONFIGURATION"
else
    echo "build configuration must be Release or Debug or PreRelease"
    exit 1
fi

echo "build target : $SCHEME"

PLISTBUDDY="/usr/libexec/PlistBuddy"

#默认源路径
echo "----------------------ENVIRONMENT VALUABLES----------------------"

if [ "$(dirname $0)" == "." ]; then
SRCROOT=$(dirname "$PWD")
else
SRCROOT=$(dirname $0)
fi

#xcode 版本
XCODE_VERSION=$(xcodebuild -version)
XCODE_VERSION=$(echo $XCODE_VERSION)
XCODE_VERSION=${XCODE_VERSION:6} # 截取左边
XCODE_VERSION=${XCODE_VERSION% Build*} # 截取右边
DEMO_VERSION='1.3.0'
echo "Xcode Version: $XCODE_VERSION"

[ -e ~/.security_profile ] && source ~/.security_profile


echo "App Version:$DEMO_VERSION RevisionNumber:$RevisionNumber"
echo "SRCROOT = $SRCROOT"

[ -e "$SRCROOT/Build/IPA" ] && rm -rf "$SRCROOT/Build/IPA"
mkdir -p "$SRCROOT/Build/IPA"
PAYLOAD="$SRCROOT/Build/IPA"
# [ -e "$SRCROOT/build" ] && rm -rf "$SRCROOT/build"

echo "----------------------ENVIRONMENT VALUABLES----------------------"

function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

function checkCommandResult()
{
    if [ $1 -ne 0 ]; then
        exit $1
    fi
}

function runBoostrap() {
    echo "run boostrap.sh ..."
    if [[ "$upload_pod" == "true" ]]; then
        sh "./boostrap.sh" -c $BUILD_CONFIGURATION -p
    else
        sh "./boostrap.sh" -c $BUILD_CONFIGURATION
    fi
}

function compileByXcode()
{
    # 由于xcode10开始更新为New Build System，但编译依赖库时会出现各种'Build input file cannot be found'的错误导致失败，当前没有找到很好的解决方法，因此暂时通过UseModernBuildSystem参数选择使用旧式的编译系统
    if version_ge $XCODE_VERSION "10.0"; then
        echo "!!! xcode version greater than or eqaul 10.0, then UseModernBuildSystem false"
    fi
    security unlock -p "$LOCAL_PWD" ~/Library/Keychains/login.keychain-db
    PROJ_FILE_PATH="$SRCROOT/$SCHEME/$SCHEME.xcodeproj/project.pbxproj"
    INFO_FILE_PATH="$SRCROOT/$SCHEME/$SCHEME/Info.plist"
    ENTITLEMENTS_PATH="$SRCROOT/$SCHEME/$SCHEME/$SCHEME.entitlements"
    # 这里删除launchPackager脚本主要是为了避免打包时会自动启动packager，而实际上packager只在debug模式下有用，打包时不需要的
    if [[ "$BUILD_CONFIGURATION" == "Debug" ]]; then
        xcodebuild $CLEAN archive -workspace "$SRCROOT/$SCHEME.xcworkspace" -scheme $SCHEME -configuration Debug -archivePath "$PAYLOAD/${SCHEME}_V${DEMO_VERSION}_B${RevisionNumber}.xcarchive" -allowProvisioningUpdates  -destination 'generic/platform=iOS'
    elif [[ "$BUILD_CONFIGURATION" == "PreRelease" ]]; then
        xcodebuild clean archive -workspace "$SRCROOT/$SCHEME.xcworkspace" -scheme $SCHEME -configuration PreRelease -archivePath "$PAYLOAD/${SCHEME}_V${DEMO_VERSION}_B${RevisionNumber}.xcarchive" -allowProvisioningUpdates -destination 'generic/platform=iOS'
    else
        xcodebuild clean archive -workspace "$SRCROOT/$SCHEME.xcworkspace" -scheme $SCHEME -configuration Release -archivePath "$PAYLOAD/${SCHEME}_V${DEMO_VERSION}_B${RevisionNumber}.xcarchive" -allowProvisioningUpdates  -destination 'generic/platform=iOS'
    fi
    checkCommandResult $?
}


function packageByXcode()
{
    EXPORT_ARCHIVE_PATH="$SRCROOT/BuildPhases/ExportOptions.plist"
    # MANIFEST_PATH="$SRCROOT/BuildPhases/mlmanifest.plist"
    echo $EXPORT_ARCHIVE_PATH
    security unlock -p "$LOCAL_PWD" ~/Library/Keychains/login.keychain-db
    xcodebuild -exportArchive -archivePath "$PAYLOAD/${SCHEME}_V${DEMO_VERSION}_B${RevisionNumber}.xcarchive" -exportPath "$PAYLOAD" -exportOptionsPlist "$SRCROOT/BuildPhases/ExportOptions.plist" -allowProvisioningUpdates
    checkCommandResult $?
    PRODUCT="product"
    BUILD_ENV="release"
    if [[ "$BUILD_CONFIGURATION" == "PreRelease" ]]; then
    BUILD_ENV="preRelease"
    elif [[ "$BUILD_CONFIGURATION" == "Debug" ]]; then
    BUILD_ENV="debug"
    fi
    IPA_PATH="$PAYLOAD/${SCHEME}_${PRODUCT}_ios-mobile_V${DEMO_VERSION}.${SDK_BUILD}_${RevisionNumber}_${BUILD_ENV}_${BUILDPACKAGE_DATETIME}.ipa"
    mv "$PAYLOAD/${SCHEME}.ipa" "$IPA_PATH"
}

function uploadPGY()
{   
    if [[ "$UPLOAD_PGY" == "true" ]]; then
        echo "begin upload ipa to pgy"
        UPLOAD_DESC=$(git log -5 --pretty=format:%s)
        sh pgyer_upload.sh -k "$PGY_API_KEY" -d "$UPLOAD_DESC" "$IPA_PATH"
    fi
}

function dSYMUpload()
{
    # 此上传仅提供脚本的编译打包的符号表上传，xcode打包需要自行手动调用命令上传
    # 对应的调研issue：https://gitlab.gz.cvte.cn/1602/client/Scorpion/-/issues/45
    UPLOAD_TOOL_PATH="$SRCROOT/BuildPhases/buglyqq-upload-symbol.jar"
    DSYMS_PATH="$PAYLOAD/${SCHEME}_V${DEMO_VERSION}_B${RevisionNumber}.xcarchive/dSYMs"
    java -jar $UPLOAD_TOOL_PATH -appid "bc64f788d5" -appkey "31163c90-815b-46c7-9a39-b33640b1e8ce" -bundleid "com.mindlinker.DualRecordingDemo" -version "$DEMO_VERSION.$RevisionNumber" -platform "IOS" -inputSymbol "$DSYMS_PATH"
}

echo "Compiling ${SCHEME}..."

runBoostrap

compileByXcode

echo "Compile ${SCHEME} Done"

echo "Packaging ${SCHEME}..."

packageByXcode

# dSYMUpload

uploadPGY

# 压缩xcarchive文件
cd "$PAYLOAD"
# 把xcarchive文件和ipa文件一起压缩
if [[ "$RELEASE_PACKAGE" == "true" ]]; then
    zip -r "${SCHEME}IOS_V${DEMO_VERSION}.zip" ${SCHEME}_V${DEMO_VERSION}_B${RevisionNumber}.xcarchive/* ${SCHEME}_${PRODUCT}_ios-mobile_V${DEMO_VERSION}.${SDK_BUILD}_${RevisionNumber}_${BUILD_ENV}_${BUILDPACKAGE_DATETIME}.ipa
else
    zip -r "${SCHEME}_V${DEMO_VERSION}.${SDK_BUILD}_B${RevisionNumber}_${BUILD_CONFIGURATION}_${BUILDPACKAGE_DATETIME}_archive.zip" ${SCHEME}_V${DEMO_VERSION}_B${RevisionNumber}.xcarchive/*
fi
checkCommandResult $?
rm -rf "${SCHEME}_V${DEMO_VERSION}_B${RevisionNumber}.xcarchive"

echo "Package ${SCHEME}_V${DEMO_VERSION}_B${RevisionNumber} Done"

echo "Finish Archive using: $(($(date +%s)-$BUILDPACKAGE_STARTTIME))s"


curl 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=ec143d22-0538-48a7-b73c-6912e8caff41' \
	-H 'Content-Type: application/json' \
    -d '
        {
            "msgtype": "markdown",
            "markdown": {
                "content": "<font color=#FFA500>**Jenkins任务构建结果通知**</font>
                >构建时间：<font color=#696969>'"${BUILD_TIME}"'</font>
                >任务名称：<font color=#696969>'"${JOB_NAME}"'</font>
                >任务地址：[点击查看]('"${URL_JOB}"')
                >构建日志：[点击查看]('"${URL_LOG}"')
                >构建状态：<font color=#008000>**Success**</font>"
            }
        }'