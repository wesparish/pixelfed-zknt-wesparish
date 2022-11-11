version = ""
project = "pixelfed"
repo = "zknt"
registry = "reg.zknt.org"
registry_credentials = "6ff44976-23cd-4cc2-902c-de8c340e65e5"
timeStamp = Calendar.getInstance().getTime().format('YYYY-MM-dd',TimeZone.getTimeZone('UTC'))

pipeline {
  agent any
  triggers {
    upstream(upstreamProjects: "../debian-php-81/trunk", threshold: hudson.model.Result.SUCCESS)
  }
    stages {
      stage('Build image') {
        steps {
          withDockerRegistry([ credentialsId: registry_credentials, url: "https://"+registry ]) {
            script {
              version = timeStamp
              def customImage = docker.build(registry+'/'+repo+'/'+project, "--pull --build-arg VERSION=$version --build-arg DATE=$timeStamp .")
              customImage.push(version)
              customImage.push("latest")
              def io_registry_credentials = "3deeee3d-6fce-4430-98dd-9b4db56f43f7"
              withDockerRegistry([ credentialsId: io_registry_credentials ]) {
                def io_registry_image = repo + '/' + project + ':' + version
                sh "docker image tag " + registry+'/'+repo+'/'+project+':'+version + ' ' + io_registry_image
                sh "docker push " + io_registry_image
                sh "docker image tag " + registry+'/'+repo+'/'+project+':'+version + ' ' + io_registry_image.split(/\:/)[0] + ":latest"
                sh "docker push " + io_registry_image.split(/\:/)[0] + ":latest"
              }

              def quay_credentials= "18fb6f7e-c6bc-4d06-9bf9-08c2af6bfc1a"
              withDockerRegistry([ credentialsId: quay_credentials, url: "https://quay.io" ]) {
                def quay_image = 'quay.io/' + repo + '/' + project + ':' + version
                sh "docker image tag " + registry+'/'+repo+'/'+project+':'+version + ' ' + quay_image
                sh "docker push " + quay_image
                sh "docker image tag " + registry+'/'+repo+'/'+project+':'+version + ' ' + quay_image.split(/\:/)[0] + ":latest"
                sh "docker push " + quay_image.split(/\:/)[0] + ":latest"
              }
            }
          }
        }
      }
    }

  post {
    always {
      sh """docker container prune -f"""
      sh """docker image prune -f"""
      sh """docker rmi -f \$(docker images -q $registry/$repo/$project:$version)"""
      sh """for image in \$(grep FROM Dockerfile | cut -d ' ' -f 2 | grep -vi -e SCRATCH -e bootstrapped | uniq); do docker rmi -f \$(docker images -q \${image}); done"""
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