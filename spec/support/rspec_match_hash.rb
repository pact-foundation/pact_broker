# checks if actual contains all the key-value pairs that expected does,
# ignoring order for any child arrays
RSpec::Matchers.define :contain_hash do |expected|
  match do |actual|
    contains_hash?(expected, actual)
  end

  failure_message do |actual|
    "expected #{actual.class} to include #{expected.class}\n" + formatted_diffs
  end

  def formatted_diffs
    @diffs.collect{ | diff| Pact::Matchers::UnixDiffFormatter.call(diff) }.join("\n")
  end

  def contains_hash?(expected, actual)
    if actual.is_a?(Array)
      actual.any? && actual.any?{|actual_item| contains_hash?(expected, actual_item)}
    else
      @diffs ||= []
      diff = Pact::Matchers.diff(expected, actual.to_hash)
      @diffs << diff
      diff.empty?
    end
  end
end
