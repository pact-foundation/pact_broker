# Releasing

Releases are made by merging a pull request.

Every push to `master` updates a draft pull request from the `release/pact_broker`
branch. It contains the next version, computed from the conventional commits
since the last tag, and the changelog entry for it. Reviewing that pull request
is how the changelog is reviewed.

To release:

1. Open the draft `chore: release vX.Y.Z` pull request and check the changelog.
2. Mark it ready for review. This runs a gem build against the release commit.
3. Merge it. The tag `vX.Y.Z` is pushed, which publishes the gem to RubyGems and
   creates the GitHub release. It then dispatches a `gem-released` event to
   `pact-broker-docker`, so the Docker images follow, and to this repository,
   where `trigger_pact_docs_update.yml` picks it up to update docs.pact.io.

To see what the next release would contain without waiting for CI:

    ruby script/release.rb prepare --dry-run

This writes the new version and changelog into the working tree and prints the
entry. Discard the changes with `git checkout -- lib/pact_broker/version.rb CHANGELOG.md`.

Pushing a `vX.Y.Z` tag by hand also publishes, bypassing the pull request. Use
this only when the normal path is broken.

## Prerequisites

Publishing to RubyGems uses OIDC via a trusted publisher configured on
rubygems.org for the `pact_broker` gem: repository `pact-foundation/pact_broker`,
workflow `release.yml`, environment `rubygems`. The `rubygems` GitHub
environment must also exist in this repository. If the `publish` job fails at
the "Configure RubyGems credentials (OIDC)" step, check these first.
