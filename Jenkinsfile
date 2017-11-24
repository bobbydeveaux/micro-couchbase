node('master') {

  stage('Build Image') {
    git url: "https://github.com/bobbydeveaux/micro-couchbase.git"
    sh "oc start-build micro-couchbase --from-file=. --follow"
  }
  stage('Deploy') {
    openshiftDeploy depCfg: 'couchbase-server', namespace: 'fbac'
    openshiftDeploy depCfg: 'couchbase-worker', namespace: 'fbac'
  }
}