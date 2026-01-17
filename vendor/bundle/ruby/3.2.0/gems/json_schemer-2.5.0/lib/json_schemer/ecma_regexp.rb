# frozen_string_literal: true
module JSONSchemer
  class EcmaRegexp
    class Syntax < Regexp::Syntax::Base
      # regexp_parser >= 2.3.0 uses syntax classes directly instead of instances
      # :nocov:
      SYNTAX = respond_to?(:implements) ? self : new
      # :nocov:
      SYNTAX.implements :anchor, Anchor::Extended
      SYNTAX.implements :assertion, Assertion::All
      # literal %i[number] to support regexp_parser < 2.2.0 (Backreference::Plain)
      SYNTAX.implements :backref, %i[number] + Backreference::Name
      # :meta_sequence, :bell, and :escape are not supported in ecma
      SYNTAX.implements :escape, Escape::Basic + (Escape::Control - %i[meta_sequence]) + (Escape::ASCII - %i[bell escape]) + Escape::Unicode + Escape::Meta + Escape::Hex + Escape::Octal
      SYNTAX.implements :property, UnicodeProperty::All
      SYNTAX.implements :nonproperty, UnicodeProperty::All
      # :comment is not supported in ecma
      SYNTAX.implements :free_space, (FreeSpace::All - %i[comment])
      SYNTAX.implements :group, Group::Basic + Group::Named + Group::Passive
      SYNTAX.implements :literal, Literal::All
      SYNTAX.implements :meta, Meta::Extended
      SYNTAX.implements :quantifier, Quantifier::Greedy + Quantifier::Reluctant + Quantifier::Interval + Quantifier::IntervalReluctant
      SYNTAX.implements :set, CharacterSet::Basic
      SYNTAX.implements :type, CharacterType::Extended
    end

    RUBY_EQUIVALENTS = {
      :anchor => {
        :bol => '\A',
        :eol => '\z'
      },
      :type => {
        :space => '[\t\r\n\f\v\uFEFF\u2029\p{Zs}]',
        :nonspace => '[^\t\r\n\f\v\uFEFF\u2029\p{Zs}]'
      }
    }.freeze

    class << self
      def ruby_equivalent(pattern)
        Regexp::Scanner.scan(pattern).map do |type, token, text|
          Syntax::SYNTAX.check!(*Syntax::SYNTAX.normalize(type, token))
          RUBY_EQUIVALENTS.dig(type, token) || text
        rescue Regexp::Syntax::NotImplementedError
          raise InvalidEcmaRegexp, "invalid token #{text.inspect} (#{type}:#{token}) in #{pattern.inspect}"
        end.join
      rescue Regexp::Scanner::ScannerError
        raise InvalidEcmaRegexp, "invalid pattern #{pattern.inspect}"
      end
    end
  end
end
