require "pact_broker/api/decorators/format_date_time"

RSpec::Matchers.define :be_datey do |_expected|
  match do |actual|
    actual.instance_of?(DateTime) || actual.instance_of?(Time)
  end

  failure_message do |actual|
    "expected #{actual.inspect} to be an instance of DateTime or Time"
  end
end

# Need this because dates get loaded into models as strings when using MySQL
RSpec::Matchers.define :be_date_time do |expected|
  match do |actual|
    PactBroker::Api::Decorators::FormatDateTime.call(expected) == PactBroker::Api::Decorators::FormatDateTime.call(actual)
  end

  failure_message do |actual|
    "expected #{PactBroker::Api::Decorators::FormatDateTime.call(expected)} to equal #{PactBroker::Api::Decorators::FormatDateTime.call(actual)}"
  end
end
