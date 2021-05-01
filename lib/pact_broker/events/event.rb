module PactBroker
  module Events
    Event = Struct.new(:name, :comment, :triggered_webhooks)
  end
end
