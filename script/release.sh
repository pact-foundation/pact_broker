#!/bin/sh
set -e
bundle exec bump ${1:-minor} --no-commit
bundle exec rake generate_changelog
git add CHANGELOG.md lib/pact_broker/version.rb
VERSION=$(ruby -r ./lib/pact_broker/version.rb -e "puts PactBroker::VERSION")
git commit -m "chore(release): version ${VERSION}"
bundle exec rake release
# git tag -a v${VERSION} -m "chore(release): version ${VERSION}"
# git push origin v${VERSION}
# git push origin master
