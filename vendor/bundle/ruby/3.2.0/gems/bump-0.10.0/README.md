[![Build Status](https://travis-ci.org/gregorym/bump.svg)](https://travis-ci.org/gregorym/bump)
[![Gem Version](https://badge.fury.io/rb/bump.svg)](http://badge.fury.io/rb/bump)

A gem to bump versions of gems and chef-cookbooks.

 - bumps version major / minor / patch / pre
 - bundles
 - commits changes

# Installation

    gem install bump

# Usage

### Show current version

    bump current

> 0.1.2

### Bump (major, minor, patch, pre)

    bump patch

> Bump version 0.1.2 to 0.1.3

### Show next version

    bump show-next patch

> 0.1.3

### Show version file path

    bump file

> lib/foo/version.rb

## Options

### `--no-commit`

Do not commit after bumping.

    bump patch --no-commit

### `--tag`

Will add a git tag like `v1.2.3` (if the current project is a git repository and `--no-commit` has not been given).

    bump patch --tag

The `--tag-prefix` option can change the tag prefix:

    bump patch --tag --tag-prefix v-     # tag as v-1.2.3
    bump patch --tag --tag-prefix ""     # tag as 1.2.3

### `--no-bundle`

Do not run `bundle` command after bumping.

    bump patch --no-bundle

### `--replace-in`

Bump the version in additional files.

    bump patch --replace-in Readme.md

### `--commit-message [MSG], -m [MSG]`

Append additional information to the commit message.

    bump patch --commit-message "Something extra"

or

    bump patch -m "Something extra"

### `--changelog`

Updates `CHANGELOG.md` when bumping.
This requires a heading (starting with `##`) that includes the previous version and a heading above that, for example:

```markdown
### Next
- Added bar

### v0.0.0 - 2019-12-24
- Added foo
```

### `--edit-changelog`

Updates CHANGELOG.md when bumping (see above), and
opens the changelog in an editor specified in `$EDITOR` (or `vi`),
then waits for the editor to be closed and continues.

```bash
EDITOR="subl -n -w" bump patch --edit-changelog
```

## Rake

```ruby
# Rakefile
require "bump/tasks"

#
# do not always tag the version
# Bump.tag_by_default = false
#
# bump the version in additional files
# Bump.replace_in_default = ["Readme.md"]
#
# Maintain changelog:
# Bump.changelog = true
# Opens the changelog in an editor when bumping
# Bump.changelog = :editor
```

    rake bump:current                           # display current version
    rake bump:show-next INCREMENT=minor         # display next minor version
    rake bump:file                              # display version file path

    # bumping using defaults for `COMMIT`, `TAG`, and `BUNDLE`
    rake bump:major
    rake bump:patch
    rake bump:minor
    rake bump:pre

    # bumping with option(s)
    rake bump:patch TAG=false BUNDLE=false      # commit, but don't tag or run `bundle`
    rake bump:patch TAG=true TAG_PREFIX=v-      # tag with a prefix 'v-' ex. the tag will look like v-0.0.1
    rake bump:patch COMMIT=false TAG=false      # don't commit, don't tag
    rake bump:minor BUNDLE=false                # don't run `bundle`

## Ruby

```ruby
require "bump"
Bump::Bump.current        # -> "1.2.3"
Bump::Bump.next_version("patch")        # -> "1.2.4"
Bump::Bump.file           # -> "lib/foo/version.rb"
Bump::Bump.run("patch")   # -> version changed
Bump::Bump.run("patch", tag: true, tag_prefix: 'v-') # -> version changed with tagging with '-v' as prefix
Bump::Bump.run("patch", commit: false, bundle:false, tag:false) # -> version changed with options
Bump::Bump.run("patch", commit_message: '[no ci]') # -> creates a commit message with 'v1.2.3 [no ci]' instead of default: 'v1.2.3'
```

# Supported locations

- `VERSION` file with `1.2.3`
- `gemspec` with `gem.version = "1.2.3"` or `Gem:Specification.new "gem-name", "1.2.3" do`
- `lib/**/version.rb` file with `VERSION = "1.2.3"`
- `metadata.rb` with `version "1.2.3"`
- `VERSION = "1.2.3"` in `lib/**/*.rb`

# Author

Gregory<br>
License: MIT
