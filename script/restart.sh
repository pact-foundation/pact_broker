#/bin/bash

root_dir=$(cd "$(dirname "$0")/.." && pwd)
example_dir="${root_dir}/example"
APP_DIR="${APP_DIR:-${example_dir}}"

cd "${APP_DIR}"

if [ -f .pid ]; then
  pid=$(cat .pid)
  echo "Pid is ${pid}"
  kill $pid
  sleep 2
fi

bundle exec rackup &
pid=$!
echo $pid > .pid
