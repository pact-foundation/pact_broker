#!/bin/bash

: "${1:?Please specify file to restore}"

script/docker/db-rm.sh
sleep 2
script/docker/db-start.sh
sleep 3

echo "restoring"
script/docker/db-restore.sh "$1"
