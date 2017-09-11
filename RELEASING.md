# Releasing

1. Increment the version in `./lib/pact_broker/version.rb`
2. Update the `CHANGELOG.md` using:

      $ bundle exec rake generate_changelog

3. Add files to git

      $ git add CHANGELOG.md lib/pact_broker/version.rb
      $ git commit -m "chore(release): version $(ruby -r ./lib/pact_broker/version.rb -e "puts PactBroker::VERSION")" && git push

3. Release:

      $ bundle exec rake release
