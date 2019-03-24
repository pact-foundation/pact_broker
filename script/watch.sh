#!/bin/bash

relative_app_dir=${1:-$PWD}
export APP_DIR=$(cd $relative_app_dir && pwd)
root_dir=$(cd "$(dirname "$0")/.." && pwd)
"${root_dir}"/script/restart.sh &
fswatch -o "${root_dir}/lib" | xargs -n1 -I{} "${root_dir}/script/restart.sh"