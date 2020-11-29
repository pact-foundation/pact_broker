#/bin/sh

cleanup() {
  docker-compose -f docker-compose-ci-mysql.yml down
}

trap cleanup EXIT
docker-compose -f docker-compose-ci-mysql.yml up --exit-code-from mysql-tests --abort-on-container-exit --remove-orphans
