#!/bin/sh

repos="pact-jvm pact-net pact-python pact-go pact-js pact"

issue_text_file=$(realpath script/dev/consumer-version-selectors-docs/issue-text.txt)

for repo in $repos; do
  cd "../${repo}"
  hub issue create --file "${issue_text_file}" --labels "documentation,help wanted,good first issue"
done
