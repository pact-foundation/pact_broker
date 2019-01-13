require 'ostruct'

RSpec.configure do | config |
  config.before(:each, job: true) do
    Thread.current[:pact_broker_thread_data] = OpenStruct.new
    Thread.current[:pact_broker_thread_data].database_connector = -> (&block) { block.call }
  end

  config.after(:each, job: true) do
    Thread.current[:pact_broker_thread_data] = nil
  end
end
