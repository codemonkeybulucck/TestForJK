# 自动设置版本号脚本。short version 为 version.config 里配置的版本号加上 git hash，version 为 git count
# 如果是 debug，则为short version 为当前用户，版本号为当前日期

INFOPLISTPATH="${TARGET_BUILD_DIR}/${CONTENTS_FOLDER_PATH}/Info.plist"

# Location of PlistBuddy
PLISTBUDDY="/usr/libexec/PlistBuddy"

echo "${CONFIGURATION}"
echo "INFOPLISTPATH = ${INFOPLISTPATH}"

cd ${PROJECT_DIR}

source "../version.config"
# Get the current git commmit hash (first 7 characters of the SHA)
GITREVSHA=$(git --git-dir="../.git" --work-tree="../" rev-parse --short HEAD)

# Get the current git count
GITCOUNT=$(git --git-dir="../.git" --work-tree="../" rev-list --no-merges HEAD --count)

if [ "${CONFIGURATION}" = "Debug" ]; then
    GITUSER=$(git --git-dir="../.git" --work-tree="../" config user.name)
    TIME=$(date "+%m%d%H%M%S")

    VERSION=$GITUSER
    VERSION_CODE=$TIME
else
    VERSION="$DEMO_VERSION"
    VERSION_CODE=$GITCOUNT
fi

echo "GIT SHA = ${GITREVSHA}"
echo "GIT COUNT = ${GITCOUNT}"
echo "INFOPLISTPATH = ${INFOPLISTPATH}"
echo "VERSION = ${VERSION}"

$PLISTBUDDY -c "Set :CFBundleVersion $VERSION_CODE" "${INFOPLISTPATH}"
$PLISTBUDDY -c "Set :CFBundleShortVersionString $VERSION" "${INFOPLISTPATH}"
$PLISTBUDDY -c "Set :GitHash $GITREVSHA" "${INFOPLISTPATH}"
