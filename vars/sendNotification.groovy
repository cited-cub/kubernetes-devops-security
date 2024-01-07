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
                ],
                [
                    "type": "section",
                    "fields": [
                        [
                            "type": "mrkdwn",
                            "text": "*Job Name:*\n${env.JOB_NAME}"
                        ],
                        [
                            "type": "mrkdwn",
                            "text": "*Build Number:*\n${env.BUILD_NUMBER}"
                        ]
                    ],
                    "accessory": [
                        "type": "image",
                        "image_url": "https://raw.githubusercontent.com/sidd-harth/devsecops-k8s-demo/main/slack-emojis/jenkins-slack.png",
                        "alt_text": "Slack Icon"
                    ]
                ],
                [
                    "type": "section",
                    "text": [
                        "type": "mrkdwn",
                        "text": "*Failed Stage Name: * `${env.failedStage}`"
                    ],
                    "accessory": [
                        "type": "button",
                        "text": [
                            "type": "plain_text",
                            "text": "Jenkins Build URL",
                        ]
                    ]
                ]
            ]
        ]
    ]

    slackSend(iconEmoji: emoji, attachments: attachments, channel: "jenkins")
}