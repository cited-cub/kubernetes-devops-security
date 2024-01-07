def call(String buildStatus = 'STARTED') {
    buildStatus = buildStatus ?: 'SUCCESS'

    def color

    if (buildStatus == 'SUCCESS') {
        color = '#47ec05'
        emoji = ':ww:'
    } else if (buildStatus == 'UNSTABLE') {
        color = '#d5ee0d'
        emoji = ':deadpool:'
    } else {
        color = '#ec2805'
        emoji = ':hulk:'
    }

    // def msg = "${buildStatus}: `${env.JOB_NAME}` #${env.BUILD_NUMBER}:\n${env.BUILD_URL}"

    // slackSend(color: color, message: msg, channel: "jenkins")
    attachments = [
        [
            "color": color,
            "blocks": [
                [
                    "type": "header",
                    "text": [
                        "type": "plain_text",
                        "text": "K8S Deployment - ${deploymentName} Pipeline",
                        "emoji": true
                    ]
                ]
            ]
        ]
    ]

    slackSend(iconEmoji: emoji, attachments: attachments)
}