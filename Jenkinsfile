project = "pixelfed"
repo = "zknt"
registry = "reg.zknt.org"
registry_credentials = "6ff44976-23cd-4cc2-902c-de8c340e65e5"
timeStamp = Calendar.getInstance().getTime().format('YYYY-MM-dd',TimeZone.getTimeZone('UTC'))

pipeline {
  agent any
  triggers {
    upstream(upstreamProjects: "../debian-php/master", threshold: hudson.model.Result.SUCCESS)
  }
  stages {
    stage('Build image') {
      steps {
        withDockerRegistry([ credentialsId: registry_credentials, url: "https://"+registry ]) {
          script {
            def customImage = docker.build(registry+'/'+repo+'/'+project, "--build-arg DATE=$timeStamp --pull .")
            customImage.push(timeStamp)
            customImage.push()

            registry_credentials = "3deeee3d-6fce-4430-98dd-9b4db56f43f7"
            withDockerRegistry([ credentialsId: registry_credentials ]) {
              def official_image = repo+'/'+project
              sh "docker image tag " + registry+'/'+repo+'/'+project + ' ' + official_image
              sh "docker image tag " + registry+'/'+repo+'/'+project + ' ' + official_image+':'+timeStamp
              sh "docker push " + official_image
              sh "docker push " + official_image+':'+timeStamp
            }
          }
        }
      }
    }
  }

  post {
    always{
      emailext body: 'build finished', subject: '[jenkins] docker ' + project + ': ' + currentBuild.result, to: 'cg@zknt.org', from: 'sysadm@zknt.org', attachLog: true
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
