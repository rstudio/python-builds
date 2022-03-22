pipeline {
  agent none
  environment {
    HOME = "."
  }
  options {
    ansiColor('xterm')
  }
  stages {
    stage('build images') {
      agent { label 'docker-4x' }
      steps {
        sh 'make docker-build'
      }
    }
    stage('push images') {
      agent { label 'docker-4x' }
      when {
        branch 'master'
      }
      steps {
        sh 'make docker-push'
      }
    }
  }
}
