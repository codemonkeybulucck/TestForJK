pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                script {
                    // 构建操作
                }
            }
        }
    }
    post {
        success {
            script {
                // 获取构建用户信息
                def buildUser = env.BUILD_USER
                // 获取构建时间
                def buildTime = currentBuild.durationString
                // 获取项目名称
                def jobName = env.JOB_NAME
                // 企业微信群机器人的Webhook地址
                def webhookUrl = 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=ec143d22-0538-48a7-b73c-6912e8caff41'
                // 构建通知消息
                def message = "## ${jobName} 构建成功\n" +
                        "- 构建时间：${buildTime}\n" +
                        "- 查看详情：[点击查看](${BUILD_URL})" +
                        "- @${buildUser}"
                // 发送通知到企业微信群
                sh "curl -X POST -H 'Content-Type: application/json' -d '{\"msgtype\":\"markdown\", \"markdown\":{\"content\":\"${message}\"}}" ${webhookUrl}
            }
        }
         failure {
            script {
                // 获取构建用户信息
                def buildUser = env.BUILD_USER
                // 获取构建时间
                def buildTime = currentBuild.durationString
                // 获取项目名称
                def jobName = env.JOB_NAME
                // 企业微信群机器人的Webhook地址
                def webhookUrl = 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=ec143d22-0538-48a7-b73c-6912e8caff41'
                // 构建通知消息
                def message = "## ${jobName} 构建失败\n" +
                        "- 构建时间：${buildTime}\n" +
                        "- 查看详情：[点击查看](${BUILD_URL})" +
                        "- @${buildUser}"
                // 发送通知到企业微信群
                sh "curl -X POST -H 'Content-Type: application/json' -d '{\"msgtype\":\"markdown\", \"markdown\":{\"content\":\"${message}\"}}" ${webhookUrl}
            }
        }
    }
}