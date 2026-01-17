# PactFfi

Ruby spike gem, to show interactions with the Pact Rust FFI methods.

Available on RubyGems - <https://rubygems.org/gems/pact-ffi>

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pact-ffi'
```

And then execute:

    bundle

Or install it yourself as:

    gem install pact-ffi

## Usage

Simple

```ruby
require 'pact/ffi'

puts PactFfi.pactffi_version
```

- See [`lib/pact/ffi.rb`](lib/pact/ffi.rb) for all available methods
- See [`spec`](spec) folder to see the tests, with the library in use
- See [`examples/area_calculator`](examples/area_calculator) folder for an example using a pact-plugin, to test the canonical area_calculator example
- Test it out in your browser, with our Killercoda example! <https://killercoda.com/safdotdev/course/safacoda/grpc_plugins_quick_start_ruby>

## Supported Platforms

- Ruby
  - This gem is compatible with all the rubies, and various platforms, it comes pre-packaged with the pact_ffi binary for each platform.
  
| OS            | Ruby          | Architecture | Supported   | Ruby Platform     |
| -------       | -------       | ------------ | ---------   | ---------         |
| MacOS         | 2.6 - 3.3     | x86_64       | ✅          | x86_64-darwin     |
| MacOS         | 2.6 - 3.3     | aarch64 (arm)| ✅          | arm64-darwin      |
| Linux         | 2.6 - 3.3     | x86_64       | ✅          | x86_64-linux      |
| Linux         | 2.6 - 3.3     | aarch64 (arm)| ✅          | aarch64-linux     |
| Linux (musl)  | 2.6 - 3.3     | x86_64       | ✅          | x86_64-linux-musl |
| Linux (musl)  | 2.6 - 3.3     | aarch64 (arm)| ✅          | aarch64-linux-musl|
| Windows       | 2.6 - 3.3     | x86_64       | ✅          | x64-mingw-ucrt    |

You can checkout the ci tests, to see all the architectures, platforms and examples tested

- GitHub Actions <https://github.com/YOU54F/pact-ruby-ffi/actions>
- Cirrus CI <https://cirrus-ci.com/github/YOU54F/pact-ruby-ffi/main>

_note_ - Alpine is currently not supported, but is on the list

- FFI libraries for your current platform - run `./script/download-libs.sh` to download

- If testing the protobuf plugin
  - `3.0` for protobuf/grpc example
    - See <https://grpc.io/docs/languages/ruby/quickstart/> for steps
    - See `examples/proto-ruby/README.md` for notes
    - ruby-grpc is not currently, on m1 hardware for the `pact-protobuf-plugin` example
    - Have the pact-protobuf plugin available
      - Run `pact-plugin-cli -y install https://github.com/pactflow/pact-protobuf-plugin/releases/latest`

## Development

- run `bin/setup` or `bundle install` to install dependencies
- run `./script/download-libs.sh` to download FFI libraries for your current platform
- run `rake spec` to run tests

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/[USERNAME>]/pact-ffi. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PactFfi project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/pact-ffi/blob/master/CODE_OF_CONDUCT.md).

## Pact Compatibility Suite

Help us implement the [Pact Compatibility Suite](https://github.com/pact-foundation/pact-compatibility-suite)

```
compatibility-suite/pact-compatibility-suite/features
├── V1
│   ├── http_consumer.feature
│   └── http_provider.feature
├── V2
│   ├── http_consumer.feature
│   └── http_provider.feature
├── V3
│   ├── generators.feature
│   ├── http_consumer.feature
│   ├── http_generators.feature
│   ├── http_matching.feature
│   ├── http_provider.feature
│   ├── matching_rules.feature
│   ├── message_consumer.feature
│   └── message_provider.feature
├── V4
│   ├── generators.feature
│   ├── http_consumer.feature ✅
│   ├── http_provider.feature
│   ├── matching_rules.feature
│   ├── message_consumer.feature ✅
│   ├── message_provider.feature ✅
│   ├── synchronous_message_consumer.feature ✅
│   └── v4.feature ✅
```
