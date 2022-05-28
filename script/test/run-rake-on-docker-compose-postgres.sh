#/bin/sh

cleanup() {
  docker-compose -f docker-compose-ci-postgres.yml down
}

trap cleanup EXIT
docker-compose -f docker-compose-ci-postgres.yml up --exit-code-from tests --abort-on-container-exit --remove-orphans
