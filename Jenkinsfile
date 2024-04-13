pipeline {
    agent any 
    environment {
        CHAT_WEBHOOK_URL = "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=ec143d22-0538-48a7-b73c-6912e8caff41"
        JOB_NAME="${JOB_BASE_NAME}"
        BUILD_NUM="$BUILD_NUMBER"
        BUILD_TIME="$BUILD_TIMESTAMP"
        URL_JOB="${BUILD_URL}"
        URL_LOG="${BUILD_URL}console"
    }
    stages {
        stage('ready') {
            steps {
                echo '准备开始构建'
            }
        }
        stage('build') {
            steps {
                echo '正在构建中'
            }
        }
    }
     post{
        success{
            sh '''
            curl "${CHAT_WEBHOOK_URL}" \
            -H "Content-Type: application/json" \
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
               }
            '
            '''
        }
        failure{
            sh '''
            curl "${CHAT_WEBHOOK_URL}" \
            -H "Content-Type: application/json" \
            -d '
               {
                    "msgtype": "markdown",
                    "markdown": {
                     "content": "<font color=#FFA500>**Jenkins任务构建结果通知**</font>
                     >构建时间：<font color=#696969>'"${BUILD_TIME}"'</font>
                     >任务名称：<font color=#696969>'"${JOB_NAME}"'</font>
                     >任务地址：[点击查看]('"${URL_JOB}"')
                     >构建日志：[点击查看]('"${URL_LOG}"')
                     >构建状态：<font color=#FF0000>**Failure**</font>"
                    }
               }
            '
            '''
        }
    }
}
