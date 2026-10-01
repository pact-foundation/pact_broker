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

## Migration notes

A `!` after the commit type, or a `BREAKING CHANGE:` footer, bumps the major
version. For a change that users may need to act on but that does not warrant a
major release, add a `Migration-Note:` footer. The changelog shows it under the
commit, and the version bump follows the commit type. `Migration Note:` in any
case is accepted.

    chore: remove the pact-support dependency

    Migration-Note: code alongside the broker can no longer rely on Pact::*
    constants. Add pact-support to your own Gemfile if that code needs them.

A note runs until the next footer and may span several paragraphs, including
fenced code blocks for before/after examples. A line that starts with a word
followed by a colon, such as `Before:` or `Pact::*`, begins a new footer and
ends the note. Reword or rewrap such lines.

## Prerequisites

Publishing to RubyGems uses OIDC via a trusted publisher configured on
rubygems.org for the `pact_broker` gem: repository `pact-foundation/pact_broker`,
workflow `release.yml`, environment `rubygems`. The `rubygems` GitHub
environment must also exist in this repository. If the `publish` job fails at
the "Configure RubyGems credentials (OIDC)" step, check these first.
