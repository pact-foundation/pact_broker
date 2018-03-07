# checks if actual contains all the key-value pairs that expected does,
# ignoring order for any child arrays
RSpec::Matchers.define :contain_hash do |expected|
  match do |actual|
    contains_hash?(expected, actual)
  end
end


def contains_hash?(expected, actual)
  if actual.is_a?(Array)
    actual.any? && actual.any?{|actual_item| contains_hash?(expected, actual_item)}
  else
    expected.all? do |key, value|
      unordered_match(actual[key], value)
    end
  end
end

def unordered_match(expected, actual)
  case
  when [expected, actual].all?{|val| val.is_a? Array }
    expected.all?{|el| actual.include? el }
  when [expected, actual].all?{|val| val.is_a? Hash }
    contains_hash?(expected, actual)
  else
    expected == actual
  end
end
