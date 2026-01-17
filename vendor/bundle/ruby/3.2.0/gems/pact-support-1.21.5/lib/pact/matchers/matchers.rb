require 'pact/configuration'
require 'pact/term'
require 'pact/something_like'
require 'pact/array_like'
require 'pact/shared/null_expectation'
require 'pact/shared/key_not_found'
require 'pact/matchers/unexpected_key'
require 'pact/matchers/unexpected_index'
require 'pact/matchers/index_not_found'
require 'pact/matchers/difference'
require 'pact/matchers/regexp_difference'
require 'pact/matchers/type_difference'
require 'pact/matchers/expected_type'
require 'pact/matchers/actual_type'
require 'pact/matchers/no_diff_at_index'
require 'pact/reification'

module Pact
  # Should be called Differs
  # Note to self: Some people are using this module directly, so if you refactor it
  # maintain backwards compatibility

  module Matchers
    NO_DIFF_AT_INDEX = NoDiffAtIndex.new
    NO_DIFF = {}.freeze
    NUMERIC_TYPES = %w[Integer Float Fixnum Bignum BigDecimal].freeze
    DEFAULT_OPTIONS = {
      allow_unexpected_keys: true,
      type: false
    }.freeze

    extend self

    def diff expected, actual, opts = {}
      calculate_diff(expected, actual, DEFAULT_OPTIONS.merge(configurable_options).merge(opts))
    end

    def type_diff expected, actual, opts = {}
      calculate_diff expected, actual, DEFAULT_OPTIONS.merge(configurable_options).merge(opts).merge(type: true)
    end

    private

    def configurable_options
      { treat_all_number_classes_as_equivalent: Pact.configuration.treat_all_number_classes_as_equivalent }
    end

    def calculate_diff expected, actual, opts = {}
      options = DEFAULT_OPTIONS.merge(opts)
      case expected
      when Hash then hash_diff(expected, actual, options)
      when Array then array_diff(expected, actual, options)
      when Regexp then regexp_diff(expected, actual, options)
      when Pact::SomethingLike then calculate_diff(expected.contents, actual, options.merge(:type => true))
      when Pact::ArrayLike then array_like_diff(expected, actual, options)
      when Pact::Term then term_diff(expected, actual, options)
      else object_diff(expected, actual, options)
      end
    end

    alias_method :structure_diff, :type_diff # Backwards compatibility

    def term_diff term, actual, options
      if actual.is_a?(Float) || actual.is_a?(Integer)
        options[:original] = actual
        options[:was_float] = actual.is_a?(Float)
        options[:was_int] = actual.is_a?(Integer)
        actual = actual.to_s
      end
      if actual.is_a?(String)
        actual_term_diff term, actual, options
      else
        RegexpDifference.new term.matcher, actual, "Expected a String matching #{term.matcher.inspect} (like #{term.generate.inspect}) but got #{class_name_with_value_in_brackets(actual)} at <path>"
      end
    end

    def actual_term_diff term, actual, options
      if term.matcher.match(actual)
        NO_DIFF
      else
        RegexpDifference.new term.matcher, options[:original] ||= actual, "Expected a Value matching #{term.matcher.inspect} (like #{term.generate.inspect}) but got #{options[:was_float] || options[:was_int] ? class_name_with_value_in_brackets(options[:original]) : actual.inspect} at <path>"
      end
    end

    def regexp_diff regexp, actual, options
      if actual.is_a?(String)
        actual_regexp_diff regexp, actual, options
      else
        RegexpDifference.new regexp, actual, "Expected a String matching #{regexp.inspect} but got #{class_name_with_value_in_brackets(actual)} at <path>"
      end
    end

    def actual_regexp_diff regexp, actual, options
      if regexp.match(actual)
        NO_DIFF
      else
        RegexpDifference.new regexp, actual, "Expected a String matching #{regexp.inspect} but got #{short_description(actual)} at <path>"
      end
    end

    def array_diff expected, actual, options
      if actual.is_a? Array
        actual_array_diff expected, actual, options
      else
        Difference.new Pact::Reification.from_term(expected), actual, type_difference_message(Pact::Reification.from_term(expected), actual)
      end
    end

    def actual_array_diff expected, actual, options
      difference = []
      diff_found = false
      length = [expected.length, actual.length].max
      length.times do | index|
        expected_item = expected.fetch(index, Pact::UnexpectedIndex.new)
        actual_item = actual.fetch(index, Pact::IndexNotFound.new)
        if (item_diff = calculate_diff(expected_item, actual_item, options)).any?
          diff_found = true
          difference << item_diff
        else
          difference << NO_DIFF_AT_INDEX
        end
      end
      diff_found ? difference : NO_DIFF
    end

    def array_like_diff array_like, actual, options
      if actual.is_a? Array
        expected_size = [array_like.min, actual.size].max
        # I know changing this is going to break something, but I don't know what it is, as there's no
        # test that fails when I make this change. I know the unpack regexps was there for a reason however.
        # Guess we'll have to change it and see!
        # expected_array = expected_size.times.collect{ Pact::Term.unpack_regexps(array_like.contents) }
        expected_array = expected_size.times.collect{ array_like.contents }
        actual_array_diff expected_array, actual, options.merge(:type => true)
      else
        Difference.new array_like.generate, actual, type_difference_message(array_like.generate, actual)
      end
    end

    def hash_diff expected, actual, options
      if actual.is_a? Hash
        actual_hash_diff expected, actual, options
      else
        Difference.new Pact::Reification.from_term(expected), actual, type_difference_message(Pact::Reification.from_term(expected), actual)
      end
    end

    def actual_hash_diff expected, actual, options
      hash_diff = expected.each_with_object({}) do |(key, expected_value), difference|
        diff_at_key = calculate_diff_at_key(key, expected_value, actual, difference, options)
        difference[key] = diff_at_key if diff_at_key.any?
      end
      hash_diff.merge(check_for_unexpected_keys(expected, actual, options))
    end

    def calculate_diff_at_key key, expected_value, actual, difference, options
      actual_value = actual.fetch(key, Pact::KeyNotFound.new)
      diff_at_key = calculate_diff(expected_value, actual_value, options)
      if actual_value.is_a?(Pact::KeyNotFound)
        diff_at_key.message = key_not_found_message(key, actual)
      end
      diff_at_key
    end

    def check_for_unexpected_keys expected, actual, options
      if options[:allow_unexpected_keys]
        NO_DIFF
      else
        (actual.keys - expected.keys).each_with_object({}) do | key, running_diff |
          running_diff[key] = Difference.new(UnexpectedKey.new, actual[key], "Did not expect the key \"#{key}\" to exist at <parent_path>")
        end
      end
    end

    def object_diff expected, actual, options
      if options[:type]
        type_difference expected, actual, options
      else
        exact_value_diff expected, actual, options
      end
    end

    def exact_value_diff expected, actual, options
      if expected == actual
        NO_DIFF
      else
        Difference.new expected, actual, value_difference_message(expected, actual, options)
      end
    end

    def type_difference expected, actual, options
      if types_match? expected, actual, options
        NO_DIFF
      else
        TypeDifference.new type_diff_expected_display(expected), type_diff_actual_display(actual), type_difference_message(expected, actual)
      end
    end

    def type_diff_expected_display expected
      ExpectedType.new(expected)
    end

    def type_diff_actual_display actual
      actual.is_a?(KeyNotFound) ?  actual : ActualType.new(actual)
    end

    # Make options optional to support existing monkey patches
    def types_match? expected, actual, options = {}
      expected.class == actual.class ||
        (is_boolean(expected) && is_boolean(actual)) ||
        (options.fetch(:treat_all_number_classes_as_equivalent, false) && is_number?(expected) && is_number?(actual))
    end

    def is_number? object
      # deal with Fixnum and Integer without warnings by using string class names
      NUMERIC_TYPES.include?(object.class.to_s)
    end

    def is_boolean object
      object == true || object == false
    end

    def has_children? object
      object.is_a?(Hash) || object.is_a?(Array)
    end

    def value_difference_message expected, actual, options = {}
      case expected
      when Pact::UnexpectedIndex
        "Actual array is too long and should not contain #{short_description(actual)} at <path>"
      else
        case actual
        when Pact::IndexNotFound
          "Actual array is too short and should have contained #{short_description(expected)} at <path>"
        else
          "Expected #{short_description(expected)} but got #{short_description(actual)} at <path>"
        end
      end
    end

    def type_difference_message expected, actual
      case expected
      when Pact::UnexpectedIndex
        "Actual array is too long and should not contain #{short_description(actual)} at <path>"
      else
        case actual
        when Pact::IndexNotFound
          "Actual array is too short and should have contained #{short_description(expected)} at <path>"
        else
          expected_desc = class_name_with_value_in_brackets(expected)
          expected_desc.gsub!("(", "(like ")
          actual_desc = class_name_with_value_in_brackets(actual)
          "Expected #{expected_desc} but got #{actual_desc} at <path>"
        end
      end
    end

    def class_name_with_value_in_brackets object
      object_desc = has_children?(object) && object.inspect.length < 100 ? "" : " (#{object.inspect})"
      object_desc = if object.nil?
        "nil"
      else
        "#{class_description(object)}#{object_desc}"
      end
    end

    def key_not_found_message key, actual
      hint = actual.any? ? "(keys present are: #{actual.keys.join(", ")})" : "in empty Hash"
      "Could not find key \"#{key}\" #{hint} at <parent_path>"
    end

    def short_description object
      return "nil" if object.nil?
      case object
      when Hash then "a Hash"
      when Array then "an Array"
      else object.inspect
      end
    end

    def class_description object
      return "nil" if object.nil?
      clazz = object.class
      case clazz.name[0]
      when /[AEIOU]/ then "an #{clazz}"
      else
        "a #{clazz}"
      end
    end
  end
end
