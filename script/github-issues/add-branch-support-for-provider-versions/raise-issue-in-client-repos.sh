#!/bin/sh

repos="pact-js pact-net pact-python pact-php pact-go pact-consumer-swift"

issue_text_file=$(realpath $(dirname "$0")/issue-text.txt)

for repo in $repos; do
  cd "../${repo}"
  hub issue create --file "${issue_text_file}" --labels "help wanted,enhancement"
done
