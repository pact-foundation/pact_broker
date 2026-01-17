#!/bin/bash
set -e

bundle install --standalone --binstubs

if [ -x ./bin/rspec ]; then
  echo "RSpec bin detected"
else
  if [ -x ./exe/rspec ]; then
    cp ./exe/rspec ./bin/rspec
    echo "RSpec restored from exe"
  else
    echo "No RSpec bin available"
    exit 1
  fi
fi
