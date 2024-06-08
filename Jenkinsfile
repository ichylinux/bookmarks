pipeline {
  agent { kubernetes { inheritFrom 'default' } }
  environment {
    KANIKO_OPTIONS = "--cache=${CACHE} --compressed-caching=false --build-arg registry=${ECR}"
  }
  stages {
    stage('build') {
      steps {
        container('kaniko') {
          ansiColor('xterm') {
            sh '/kaniko/executor -f `pwd`/Dockerfile.base -c `pwd` -d=${ECR}/bookmarks/base:latest ${KANIKO_OPTIONS}'
            sh '/kaniko/executor -f `pwd`/Dockerfile.test -c `pwd` -d=${ECR}/bookmarks/test:latest ${KANIKO_OPTIONS}'
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
        RELEASE_TAG = "v1.1.0-${BUILD_NUMBER}"
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
            container('kaniko') {
              ansiColor('xterm') {
                sh '/kaniko/executor -f `pwd`/Dockerfile.app -c `pwd` -d=${ECR}/bookmarks/app:${RELEASE_TAG} ${KANIKO_OPTIONS}'
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
    sh 'ln -snf /var/app/current/node_modules node_modules
    sh 'bundle exec rails db:reset'
    sh 'bundle exec rake assets:precompile'
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
