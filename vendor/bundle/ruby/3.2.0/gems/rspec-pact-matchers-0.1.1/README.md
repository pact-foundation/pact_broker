# RSpec Pact Matchers

This gem provides a `match_pact` RSpec matcher that uses the underlying matching logic from the [Pact][pact-gem] gem to compare two "JSON" object graphs (ie. Hashes, Arrays, and the simple object types that result from parsing a JSON document into a Ruby data structure). The expected JSON object graph may be "plain old Ruby", or it may use the Pact [matchers][[pact-matchers]] (`Pact.like`, `Pact.term` etc).

Note that Pact is a library designed for testing consumer contracts, and it follows [Postel's law][[postels-law]] in being "liberal in what you accept from others". This means that it allows unexpected keys in the actual document by default. If you are using the `match_pact` to test data that will be sent to another system, you should "be conservative in what you send" and use the `{allow_unexpected_keys: false}` option.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rspec-pact-matchers'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rspec-pact-matchers

## Usage

The RSpec Pact matcher will allow


```ruby
require 'rspec/pact/matchers'

# Simple match, allowing extra keys

expect(thing: 'foo', other_thing: 'bar').to match_pact(thing: 'foo')

# Disallowing extra keys

expect(thing: 'foo', other_thing: 'bar').to match_pact({thing: 'foo'}, {allow_unexpected_keys: false}) # This will fail

# Using Pact matchers

expect(thing: 'foo', other_thing: 'bar').to match_pact(Pact.like(thing: 'wiffle'))

```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pact-foundation/rspec-pact-matchers.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[pact-gem]: https://github.com/realestate-com-au/pact
[pact-matchers]: https://github.com/realestate-com-au/pact/wiki/v2-flexible-matching
[postels-law]: https://en.wikipedia.org/wiki/Robustness_principle
