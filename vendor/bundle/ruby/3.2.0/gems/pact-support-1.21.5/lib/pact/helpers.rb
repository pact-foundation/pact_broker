require 'pact/something_like'
require 'pact/term'
require 'pact/array_like'

# Protected, exposed through Pact.term and Pact.like, and included in Pact::Consumer::RSpec

module Pact
  module Helpers

    def self.included(base)
      base.extend(self)
    end

    def term arg1, arg2 = nil
      case arg1
      when Hash then Pact::Term.new(arg1)
      when Regexp then Pact::Term.new(matcher: arg1, generate: arg2)
      when String then Pact::Term.new(matcher: arg2, generate: arg1)
      else
        raise ArgumentError, "Cannot create a Pact::Term from arguments #{arg1.inspect} and #{arg2.inspect}. Please provide a Regexp and a String."
      end
    end

    def like content
      Pact::SomethingLike.new(content)
    end

    def each_like content, options = {}
      Pact::ArrayLike.new(content, options)
    end

    def like_uuid uuid
      Pact::Term.new(generate: uuid, matcher: /^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$/)
    end

    def like_datetime datetime
      Pact::Term.new(generate: datetime, matcher: /^\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d:[0-5]\d([+-][0-2]\d:[0-5]\d|Z)$/)
    end

    def like_datetime_with_milliseconds datetime
      Pact::Term.new(generate: datetime, matcher: /^\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d:[0-5]\d\.\d{3}([+-][0-2]\d:[0-5]\d|Z)$/)
    end

    alias_method :like_datetime_with_miliseconds, :like_datetime_with_milliseconds

    def like_date date
      Pact::Term.new(generate: date, matcher: /^\d{4}-[01]\d-[0-3]\d$/)
    end

    # regex matched with pact-jvm 
    # https://github.com/pact-foundation/pact-jvm/blob/00442e6df51e5be906ed470b19859246312e5c83/core/matchers/src/main/kotlin/au/com/dius/pact/core/matchers/MatcherExecutor.kt#L56-L59
    def like_integer int
      Pact::Term.new(generate: int, matcher: /^-?\d+$/)
    end

    def like_decimal float
      Pact::Term.new(generate: float, matcher: /^0|-?\d+\.\d*$/)
    end

    def like_datetime_rfc822 datetime
      Pact::Term.new(
        generate: datetime,
        matcher: /(?x)(Mon|Tue|Wed|Thu|Fri|Sat|Sun),
                        \s\d{2}\s
                        (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)
                        \s\d{4}\s\d{2}:\d{2}:\d{2}\s(\+|-)\d{4}/
      )
    end
  end
end
