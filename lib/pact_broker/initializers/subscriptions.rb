require "pact_broker/events/subscriber"
require "pact_broker/integrations/event_listener"

PactBroker::Events.subscribe(PactBroker::Integrations::EventListener.new)
