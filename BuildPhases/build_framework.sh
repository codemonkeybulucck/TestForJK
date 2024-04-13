#!/bin/sh

RevisionNumber=$(git rev-list --count HEAD --no-merges)
GitRevSHA=$(git rev-parse --short HEAD)
BUILDPACKAGE_DATETIME=$(date +%Y%m%d)

if [[ -z "$SRCROOT" ]]; then
	if [ "$(dirname $0)" == "." ]; then
		SRCROOT=$(dirname "$PWD")
	else
		SRCROOT="$PWD"
	fi
fi

#参数处理
while getopts "c:p" opt
do
case "$opt" in
c) development_mode="$OPTARG";; # 参数configuration：Release, Debug, PreRelease
p) upload_pod="true";;
\?)     # unknown flag
echo >&2 \
"usage: $0 [-c configuration -p pod_update>]"
exit 1;;
esac
done
shift `expr $OPTIND - 1`

#工程名
project_name=MLDualRecording
#要编译的sheme_name名
sheme_name=${project_name}
#打包模式 Debug/Release 默认为Release
if [ -z "$development_mode" ]; then
development_mode=Release
fi
#工程所在目录
if [ "$(dirname $0)" == "." ]; then
project_dir=$(dirname "$PWD")
else
project_dir=$(dirname $0)
fi
#编译之后的文件夹路径
build_dir=${project_dir}/Build/Framework
# workspace路径
workspace_path=${project_dir}/${project_name}.xcworkspace
#真机编译后生成的.framework文件路径
building_dir=${build_dir}/${development_mode}-iphoneos
device_dir=${building_dir}/${project_name}.framework
dsym_dir=${building_dir}/${project_name}.framework.dSYM
#目标文件夹路径(即包含目标.framework文件与bundle文件)
install_dir=${build_dir}/Products/

#xcode 版本
XCODE_VERSION=$(xcodebuild -version)
XCODE_VERSION=$(echo $XCODE_VERSION)
XCODE_VERSION=${XCODE_VERSION:6} # 截取左边
XCODE_VERSION=${XCODE_VERSION% Build*} # 截取右边
echo "Xcode Version: $XCODE_VERSION"

[ -e ~/.security_profile ] && source ~/.security_profile
source "$project_dir/version.config"

function build_clean {
    echo "**************开始清除缓存**************"
    #判断Build文件夹是否存在,存在则删除
    if [ -d "${project_dir}/Build" ]; then
        rm -rf "${project_dir}/Build"
    fi
    echo "**************清除缓存结束**************"
}

function run_boostrap() {
    echo "run boostrap.sh ..."
    if [[ "$upload_pod" == "true" ]]; then
        sh "./boostrap.sh" -c $development_mode -p
    else
        sh "./boostrap.sh" -c $development_mode
    fi
}

function checkCommandResult()
{
    if [ $1 -ne 0 ]; then
        exit $1
    fi
}

function build_framework {
    echo "**************开始编译framework**************"
    # 执行编译
    echo "${build_dir}"
    xcodebuild clean build -workspace ${workspace_path} -scheme ${sheme_name} -configuration ${development_mode} -sdk iphoneos SYMROOT="${build_dir}/"
    checkCommandResult $?
    # 判断install_dir文件夹是否存在,不存在则创建
    if [ ! -d "${install_dir}" ]; then
        mkdir -p "${install_dir}"
    fi
    #将真机编译的.framework 拷贝到 目标文件夹中
    cp -R "${device_dir}" "${install_dir}"
    # 将dsym文件也放到目标文件夹中
    cp -R "${dsym_dir}" "${install_dir}"
    cd "${install_dir}"
    zip -r "MLDualRecording_V${MLDRS_VERSION}.${GitRevSHA}_B${RevisionNumber}_${development_mode}_${BUILDPACKAGE_DATETIME}.zip" "${project_name}.framework"
    zip -r "MLDualRecording_V${MLDRS_VERSION}.${GitRevSHA}_B${RevisionNumber}_${development_mode}_${BUILDPACKAGE_DATETIME}_dSYM.zip" "${project_name}.framework.dSYM"
    rm -rf "$building_dir"
    echo "**************编译framework结束**************"
}

function open_build_dir {
    echo "************** Build Successful! Congratulations! 🍺🧨🍰🎆🍺🧨🍰🎆🍺🧨🍰 **************"
    #打开目标文件夹
    # open "${install_dir}"
}

# 调用
build_clean
run_boostrap
build_framework
open_build_dir
