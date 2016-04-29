# Releasing

1. Increment the version in `lib/pact/support/version.rb`
2. Update the `CHANGELOG.md` using:

      $ git log --pretty=format:'  * %h - %s (%an, %ad)' vX.Y.Z..HEAD

3. Add files to git

      $ git add CHANGELOG.md lib/pact_broker/version.rb

3. Release:

      $ bundle exec rake release
