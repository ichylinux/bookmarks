pipeline {
  agent { label 'master' }
  environment {
      COVERAGE = 'true'
      EXPAND = 'false'
      FORMAT = 'junit'
  }
  stages {
    stage('test') {
      steps {
        test()
      }
      post {
        always { publish() }
        success { sh 'git push origin release' }
      }
    }
  }
}

def test() {
  ansiColor('xterm') {
    sh 'bundle install --quiet'
    sh 'yarn install'
    sh 'bundle exec rails log:clear'
    sh 'bundle exec rails tmp:cache:clear'
    sh 'bundle exec rake dad:setup:test'
    sh 'bundle exec rails db:schema:load'
    sh 'bundle exec rake test'
    sh 'bundle exec rake dad:test'
  }
}

def publish() {
  junit 'test/reports/**/*.xml'
  script {
    step([$class: 'RcovPublisher', reportDir: "coverage/rcov"])
  }
}
