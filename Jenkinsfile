version = ""
project = "pixelfed"
repo = "zknt"
timeStamp = Calendar.getInstance().getTime().format('YYYY-MM-dd',TimeZone.getTimeZone('UTC'))

pipeline {
  agent any
  environment {
    IO_CRED = credentials("3deeee3d-6fce-4430-98dd-9b4db56f43f7")
    QUAY_CRED = credentials("18fb6f7e-c6bc-4d06-9bf9-08c2af6bfc1a")
  }
    stages {
      stage('Prepare') {
        steps {
          script {
            sh "buildah login -u " + IO_CRED_USR+ " -p " + IO_CRED_PSW + " docker.io"
            sh "buildah login -u " + QUAY_CRED_USR+ " -p " + QUAY_CRED_PSW + " quay.io"
            sh "buildah manifest create pixelfed-dev"
            sh "buildah manifest create pixelfed-dev-fpm"
          }
        }
      }
      stage('Build dev amd64') {
        steps {
          script {
            sh "TMPDIR=/buildah/tmp buildah bud -f Containerfile --build-arg DATE=$timeStamp --manifest pixelfed-dev --arch amd64"
          }
        }
      }
      stage('Build dev arm64') {
        steps {
          script {
            sh "TMPDIR=/buildah/tmp buildah bud -f Containerfile --build-arg DATE=$timeStamp --manifest pixelfed-dev --arch arm64"
          }
        }
      }
      stage('Build dev-fpm amd64') {
        steps {
          script {
            sh "TMPDIR=/buildah/tmp buildah bud -f Containerfile.fpm --build-arg DATE=$timeStamp --manifest pixelfed-dev-fpm --arch amd64"
          }
        }
      }
      stage('Build dev-fpm arm64') {
        steps {
          script {
            sh "TMPDIR=/buildah/tmp buildah bud -f Containerfile.fpm --build-arg DATE=$timeStamp --manifest pixelfed-dev-fpm --arch arm64"
          }
        }
      }
      stage('Upload to quay.io') {
        steps {
          script {
            sh "buildah manifest push --all pixelfed-dev docker://quay.io/zknt/pixelfed:dev"
            sh "buildah manifest push --all pixelfed-dev docker://quay.io/zknt/pixelfed:latest"
            sh "buildah manifest push --all pixelfed-dev docker://quay.io/zknt/pixelfed:$timeStamp"
            sh "buildah manifest push --all pixelfed-dev-fpm docker://quay.io/zknt/pixelfed:dev-fpm"
            sh "buildah manifest push --all pixelfed-dev-fpm docker://quay.io/zknt/pixelfed:fpm"
            sh "buildah manifest push --all pixelfed-dev-fpm docker://quay.io/zknt/pixelfed:$timeStamp-fpm"
          }
        }
      }
      stage('Upload to docker.io') {
        steps {
          script {
            sh "buildah manifest push --all pixelfed-dev docker://docker.io/zknt/pixelfed:dev"
            sh "buildah manifest push --all pixelfed-dev docker://docker.io/zknt/pixelfed:latest"
            sh "buildah manifest push --all pixelfed-dev docker://docker.io/zknt/pixelfed:$timeStamp"
            sh "buildah manifest push --all pixelfed-dev-fpm docker://docker.io/zknt/pixelfed:dev-fpm"
            sh "buildah manifest push --all pixelfed-dev-fpm docker://docker.io/zknt/pixelfed:fpm"
            sh "buildah manifest push --all pixelfed-dev-fpm docker://docker.io/zknt/pixelfed:$timeStamp-fpm"
          }
        }
      }
    }

  post {
    always {
      sh """buildah rmi -af"""
      emailext body: 'build finished', subject: '[jenkins] docker '+project+'('+timeStamp+'): ' + currentBuild.result, to: 'cg@zknt.org', from: 'sysadm@zknt.org', attachLog: true
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
