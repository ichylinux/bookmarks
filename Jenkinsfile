pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: ichylinux/docker:20.03
    imagePullPolicy: Always
    command:
    - cat
    tty: true
    securityContext:
      privileged: true
    volumeMounts:
      - name: docker-config
        mountPath: /root/.docker/
      - name: aws-secret
        mountPath: /root/.aws/
      - name: docker-socket
        mountPath: /var/run/docker.sock
  volumes:
    - name: docker-config
      configMap:
        name: docker-config
    - name: aws-secret
      secret:
        secretName: aws-secret
    - name: docker-socket
      hostPath:
        path: /var/run/docker.sock
        type: File
"""
    }
  }
  stages {
    stage('build') {
      steps {
        container('docker') {
          ansiColor('xterm') {
            sh "docker build --no-cache=${NO_CACHE} -f Dockerfile.base -t bookmarks/base:latest --build-arg registry=${ECR} --network=host ."
            sh "docker tag bookmarks/base:latest ${ECR}/bookmarks/base:latest"
            sh "docker push ${ECR}/bookmarks/base:latest"
            sh "docker build --no-cache=${NO_CACHE} -f Dockerfile.test -t bookmarks/test:latest --network=host ."
            sh "docker tag bookmarks/test:latest ${ECR}/bookmarks/test:latest"
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
"""
        }
      }
      environment {
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
        RELEASE_TAG = "v1.0.0-${BUILD_NUMBER}"
      }
      steps {
        container('docker') {
          ansiColor('xterm') {
            sh "docker build --no-cache=${NO_CACHE} -f Dockerfile.app -t ${ECR}/bookmarks/app:latest --network=host ."
            sh "docker tag ${ECR}/bookmarks/app:latest ${ECR}/bookmarks/app:${RELEASE_TAG}"
            sh "docker push ${ECR}/bookmarks/app:latest"
            sh "docker push ${ECR}/bookmarks/app:${RELEASE_TAG}"
          }
        }
        container('jnlp') {
          sh "git push origin HEAD:release"
          sh "git tag ${RELEASE_TAG}"
          sh "git push origin ${RELEASE_TAG}"
        }
      }
    }
  }
}

def test() {
  ansiColor('xterm') {
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
