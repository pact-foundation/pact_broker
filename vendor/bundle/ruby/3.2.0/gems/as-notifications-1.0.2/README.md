AS::Notification -- Provides an instrumentation API for Ruby
------------------------------------------------------------

AS::Notification is an extraction of ActiveSupport::Notifications from
[Rails](https://github.com/rails/rails/tree/main/activesupport).

* [API documentation](http://rubydoc.info/github/bernd/as-notifications/main/AS/Notifications)
* [ChangeLog](CHANGELOG.md)

## Installation

    $ gem install as-notifications

## Changes to ActiveSupport::Notifications

### v0.1.0

* Change module name from `ActiveSupport::Notifications` to
  `AS::Notifications` to avoid conflicts with activesupport
* Change `require` calls for `active_support/notifications` to
  `as/notifications`
* Disable loading `load_paths` file in tests
* Revert [rails/rails@45448a5](https://github.com/rails/rails/commit/45448a5)
  changes to avoid `thread_safe` gem dependency

### v1.0.0

* Adjust `test/notifications/instrumenter_test.rb` and `test/abstract_unit.rb`
  to unbreak the tests on Ruby 1.8.
* Include `define_singleton_method` and `public_send` [backports](https://github.com/marcandre/backports)
  to make `ActiveSupport::PerThreadRegistry` work on Ruby 1.8.
