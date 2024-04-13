#!/bin/sh

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

if [[ -z "$SRCROOT" ]]; then
    if [ "$(dirname $0)" == "." ]; then
        SRCROOT=$(dirname "$PWD")
    else
        SRCROOT="$PWD"
    fi
    echo "SRCROOT: $SRCROOT"
fi


function update_pods() 
{
    echo "updating pod ..."
    # 清除pod缓存

    rm -rf ../Pods
    
    if [ -n "$upload_pod" ]; then
        pod update
    else
        pod install
    fi
}

git submodule update --init --recursive
update_pods