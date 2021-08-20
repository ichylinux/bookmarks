pipeline {
  agent { kubernetes { inheritFrom 'default' } }
  stages {
    stage('build') {
      steps {
        container('docker') {
          ansiColor('xterm') {
            sh "docker build --no-cache=${NO_CACHE} -f Dockerfile.base -t ${ECR}/bookmarks/base:latest --build-arg registry=${ECR} --network=host ."
            sh "docker push ${ECR}/bookmarks/base:latest"
            sh "docker build --no-cache=${NO_CACHE} -f Dockerfile.test -t ${ECR}/bookmarks/test:latest --build-arg registry=${ECR} --network=host ."
            sh "docker push ${ECR}/bookmarks/test:latest"
          }
        }
      }
    }
    stage('test') {
      agent {
        kubernetes {
          yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: bookmarks
    image: ${ECR}/bookmarks/test:latest
    imagePullPolicy: Always
    command:
    - cat
    tty: true
  - name: mysql
    image: mysql:5.7
    env:
    - name: MYSQL_ALLOW_EMPTY_PASSWORD
      value: yes
    - name: MYSQL_DATABASE
      value: bookmarks_test
    - name: MYSQL_USER
      value: bookmarks
    - name: MYSQL_PASSWORD
      value: bookmarks
"""
        }
      }
      environment {
        COVERAGE = 'true'
        FORMAT = 'junit'
        RAILS_ENV = 'test'
      }
      steps {
        container('mysql') {
          sh """
while ! mysqladmin ping --user=root -h 127.0.0.1 --port=3306 --silent; do
    sleep 1
done
"""
        }
        container('bookmarks') {
          test()
        }
      }
      post {
        always { publish() }
      }
    }
    stage('release') {
      environment {
        RELEASE_TAG = "v1.0.0-${BUILD_NUMBER}"
      }
      parallel {
        stage('tagging') {
          steps {
            container('jnlp') {
              sshagent(credentials: [env.GITHUB_SSH_KEY]) {
                sh "git push origin HEAD:release"
                sh "git tag ${RELEASE_TAG}"
                sh "git push origin ${RELEASE_TAG}"
              }
            }
          }
        }
        stage('artifact') {
          steps {
            container('docker') {
              ansiColor('xterm') {
                sh "docker build --no-cache=${NO_CACHE} -f Dockerfile.app -t ${ECR}/bookmarks/app:latest --build-arg registry=${ECR} --network=host ."
                sh "docker tag ${ECR}/bookmarks/app:latest ${ECR}/bookmarks/app:${RELEASE_TAG}"
                sh "docker push ${ECR}/bookmarks/app:latest"
                sh "docker push ${ECR}/bookmarks/app:${RELEASE_TAG}"
              }
            }
          }
        }
      }
    }
  }
}

def test() {
  ansiColor('xterm') {
    sh 'bundle exec rails db:reset'
    sh 'bundle exec rails test'
    sh 'bundle exec rake dad:test'
  }
}

def publish() {
  junit 'test/reports/**/*.xml'
  script {
    step([$class: 'RcovPublisher', reportDir: "coverage/rcov"])
  }
}
