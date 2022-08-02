pipeline {
  agent {
    dockerfile {
      dir 'jenkins'
      label 'docker'
      additionalBuildArgs '--build-arg DOCKER_GID=$(stat -c %g /var/run/docker.sock) --build-arg JENKINS_UID=$(id -u jenkins) --build-arg JENKINS_GID=$(id -g jenkins)'
      args '-v /var/run/docker.sock:/var/run/docker.sock --group-add docker'
    }
  }
  environment {
    HOME = "."
  }
  options {
    ansiColor('xterm')
    timeout(time: 4, unit: 'HOURS')
  }
  parameters {
    choice(name: 'ENVIRONMENT', choices: ['staging', 'production'],
           description: 'Which environment to use to rebuild all the python binaries.')
  }
  stages {
    stage('Break Glass') {
      steps {
        withAWS(role:'python-builds-deploy') {
          sh "make break-glass.${params.ENVIRONMENT}"
        }
      }
    }
  }
}
