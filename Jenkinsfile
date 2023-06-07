version = ""
project = "pixelfed"
repo = "zknt"
registry = "reg.zknt.org"
timeStamp = Calendar.getInstance().getTime().format('YYYY-MM-dd',TimeZone.getTimeZone('UTC'))

pipeline {
  agent any
  environment {
    ZKNT_CRED = credentials("6ff44976-23cd-4cc2-902c-de8c340e65e5")
    IO_CRED = credentials("3deeee3d-6fce-4430-98dd-9b4db56f43f7")
    QUAY_CRED = credentials("18fb6f7e-c6bc-4d06-9bf9-08c2af6bfc1a")
  }
    stages {
      stage('Build image') {
        steps {
          script {
            sh "buildah login -u " + ZKNT_CRED_USR + " -p " + ZKNT_CRED_PSW + " reg.zknt.org"
            def image = registry + '/' + repo + '/' + project
            sh "buildah bud -f Containerfile --build-arg DATE=$timeStamp -t pixelfed:test"
            sh "buildah tag pixelfed:test reg.zknt.org/zknt/pixelfed:test"
            sh "buildah push " + image + ':test'
          }
          script {
            sh "buildah login -u $IO_CRED_USR -p $IO_CRED_PSW docker.io"
            sh "buildah tag pixelfed:test docker.io/zknt/pixelfed:test"
            sh "buildah push docker.io/zknt/pixelfed:test"
          }
          script {
            sh "buildah login -u $QUAY_CRED_USR -p $QUAY_CRED_PSW quay.io"
            sh "buildah tag pixelfed:test quay.io/zknt/pixelfed:test"
            sh "buildah push quay.io/zknt/pixelfed:test"
          }
        }
      }
    }

  post {
    always {
      sh """buildah rmi -af"""
      emailext body: 'build finished', subject: '[jenkins] docker '+project+'('+version+'): ' + currentBuild.result, to: 'cg@zknt.org', from: 'sysadm@zknt.org', attachLog: true
    }
  }
  options {
    buildDiscarder(BuildHistoryManager([
      [
        conditions: [
          BuildResult(matchFailure: true)
        ],
        matchAtMost: 4,
        continueAfterMatch: false
      ],
      [
        conditions: [
          BuildResult(matchSuccess: true)
        ],
        matchAtMost: 4,
        continueAfterMatch: false
      ],
      [
        conditions: [
          BuildResult(matchSuccess: true, matchFailure: true)
        ],
        actions: [DeleteBuild()]
      ]
    ]))
  }
}
