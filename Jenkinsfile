project = "pixelfed"
repo = "zknt"
registry = "reg.zknt.org"
registry_credentials = "6ff44976-23cd-4cc2-902c-de8c340e65e5"
timeStamp = Calendar.getInstance().getTime().format('YYYY-MM-dd',TimeZone.getTimeZone('UTC'))
official_image = ""

pipeline {
  agent any
  triggers {
    upstream(upstreamProjects: "../debian-php/trunk", threshold: hudson.model.Result.SUCCESS)
  }
  stages {
    stage('Build image') {
      steps {
        withDockerRegistry([ credentialsId: registry_credentials, url: "https://"+registry ]) {
          script {
            def customImage = docker.build(registry+'/'+repo+'/'+project, "--build-arg DATE=$timeStamp --pull .")
            customImage.push(timeStamp)
            customImage.push()

            io_registry_credentials = "3deeee3d-6fce-4430-98dd-9b4db56f43f7"
            withDockerRegistry([ credentialsId: io_registry_credentials ]) {
              official_image = repo+'/'+project
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
    success {
      withCredentials([string(credentialsId: '90700f9c-c5cf-449b-81af-d854c08265f5', variable: 'CONFIG_JSON')]) {
        withDockerRegistry([ credentialsId: registry_credentials, url: "https://"+registry ]) {
         sh "docker pull reg.zknt.org/zknt/toot"
         sh 'docker run -i -e CONFIG_JSON=$CONFIG_JSON -e TOOT="Successfully built and pushed new image: '+official_image+':'+timeStamp+' https://hub.docker.com/r/zknt/pixelfed/tags" reg.zknt.org/zknt/toot'
        }
      }
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
