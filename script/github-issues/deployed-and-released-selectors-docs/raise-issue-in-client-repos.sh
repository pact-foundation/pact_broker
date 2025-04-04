#!/usr/bin/env bash

repos="pact-js pact-jvm pact-net pact-python scala-pact pact-php pact-go pact pact-reference"

issue_text_file=$(realpath $(dirname "$0")/issue-text.txt)

for repo in $repos; do
	cd "../${repo}"
	hub issue create --file "${issue_text_file}" --labels "help wanted,good first issue,enhancement"
done
