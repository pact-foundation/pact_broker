#!/bin/sh
set -e
bundle exec bump ${1:-minor} --no-commit
bundle exec rake generate_changelog
git add CHANGELOG.md lib/pact_broker/version.rb
git commit -m "chore(release): version $(ruby -r ./lib/pact_broker/version.rb -e "puts PactBroker::VERSION")" && git push
bundle exec rake release
