RSpec::Matchers.define :be_datey do |_expected|
  match do |actual|
    actual.instance_of?(DateTime) || actual.instance_of?(Time)
  end

  failure_message do |actual|
    "expected #{actual.inspect} to be an instance of DateTime or Time"
  end
end
