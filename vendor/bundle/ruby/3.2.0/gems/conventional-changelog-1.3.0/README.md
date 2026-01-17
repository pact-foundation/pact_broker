[![Build Status](https://travis-ci.org/dcrec1/conventional-changelog-ruby.svg?branch=master)](https://travis-ci.org/dcrec1/conventional-changelog-ruby)
[![Code Climate](https://codeclimate.com/github/dcrec1/conventional-changelog-ruby/badges/gpa.svg)](https://codeclimate.com/github/dcrec1/conventional-changelog-ruby)
[![Test Coverage](https://codeclimate.com/github/dcrec1/conventional-changelog-ruby/badges/coverage.svg)](https://codeclimate.com/github/dcrec1/conventional-changelog-ruby)

# Conventional::Changelog

Generates a CHANGELOG.md file from Git metadata using the AngularJS commit conventions.

- [AngularJS Git Commit Message Conventions](https://docs.google.com/document/d/1QrDFcIiPjSLDn3EL15IJygNPiHORgU1_OOAqWjiDU5Y/)

Since version 1.2.0 the scopes are optional.


## Installation

    $ gem install conventional-changelog


## Usage

    $ conventional-changelog
    $ conventional-changelog version=vX.Y.Z

or programatically:

```ruby
require 'conventional_changelog'
ConventionalChangelog::Generator.new.generate!
ConventionalChangelog::Generator.new.generate! version: "vX.Y.Z"
```

Version param should follow your Git tags format

## Examples

Converts this:

    2015-03-30 feat(admin): increase reports ranges
    2015-03-30 fix(api): fix annoying bug
    2015-03-28 feat(api): add cool service
    2015-03-28 feat(api): add cool feature
    2015-03-28 feat(admin): add page to manage users

into this:

    <a name="2015-03-30"></a>
    ### 2015-03-30
    
    
    #### Features
    
    * **admin**
      * increase reports ranges (4303fd4)
    
    
    #### Bug Fixes
    
    * **api**
      * fix annoying bug (4303fd5)
    
    
    <a name="2015-03-28"></a>
    ### 2015-03-28
    
    
    #### Features
    
    * **api**
      * add cool service (4303fd6)
      * add cool feature (4303fd7)
    
    * **admin**
      * add page to manage users (4303fd8)

## Contributing

1. Fork it ( https://github.com/dcrec1/conventional-changelog-ruby/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
