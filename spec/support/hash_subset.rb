require "json"
require "pact_broker/unified_diff"

# Deep subset comparison for specs: every expected key must be present with a
# matching value, arrays must match element for element, and extra keys in the
# actual hash are allowed unless allow_unexpected_keys is false.
module HashSubset
  def self.match?(expected, actual, allow_unexpected_keys: true)
    case expected
    when Hash
      match_hash?(expected, actual, allow_unexpected_keys: allow_unexpected_keys)
    when Array
      match_array?(expected, actual, allow_unexpected_keys: allow_unexpected_keys)
    else
      expected == actual
    end
  end

  def self.match_hash?(expected, actual, allow_unexpected_keys:)
    return false unless actual.is_a?(Hash)
    return false if !allow_unexpected_keys && (actual.keys - expected.keys).any?

    expected.all? do |key, value|
      actual.key?(key) && match?(value, actual[key], allow_unexpected_keys: allow_unexpected_keys)
    end
  end
  private_class_method :match_hash?

  def self.match_array?(expected, actual, allow_unexpected_keys:)
    return false unless actual.is_a?(Array) && actual.length == expected.length

    expected.zip(actual).all? { |e, a| match?(e, a, allow_unexpected_keys: allow_unexpected_keys) }
  end
  private_class_method :match_array?

  def self.diff(expected, actual)
    PactBroker::UnifiedDiff.call(JSON.pretty_generate(expected), JSON.pretty_generate(actual))
  end
end
