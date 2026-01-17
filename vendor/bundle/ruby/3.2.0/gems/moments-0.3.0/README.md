# Moments [![Gem Version](https://badge.fury.io/rb/moments.svg)](http://badge.fury.io/rb/moments)

Handles time differences and calculations.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'moments'
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install moments
```

## Usage

```ruby
require 'moments'

t1 = Time.new 2015, 1, 1, 0, 0, 0
t2 = Time.now # 2020, 8, 6, 19, 29, 6

diff = Moments.difference t1, t2

puts diff.to_hash
# { years: 5, months: 7, days: 5, hours: 19, minutes: 29, seconds: 6 }

puts diff.in_months
# 67 (5 * 12 + 7)
# there are also methods for each component

from = Time.new(2022, 8, 4, 15, 52, 25, '-06:00')
to = Time.new(2022, 8, 18, 15, 52, 31, '-06:00')

difference = Moments.difference(from, to, :precise).in_minutes
# returns: 20_160.1
# supports: in_weeks, in_days, in_hours, in_minutes

ago = Moments.ago t1

puts ago.to_hash
# { years: 5, months: 7, days: 5, hours: 19, minutes: 29, seconds: 6 }

puts ago.humanized
# 5 years, 7 months, 5 days, 19 hours, 29 minutes and 6 seconds

# #humanized takes care of signularity and omits 0 values
puts Moments.difference(t1, Time.new(2015, 2, 1, 19, 0, 1)).humanized
# 1 month, 19 hours and 1 second
```

## Contributing

1. Fork it ( https://github.com/excpt/moments/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
