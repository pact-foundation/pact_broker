require "pact_broker/events/subscriber"

module PactBroker
  module Api
    module Resources
      module EventMethods
        def subscribe(listener)
          PactBroker::Events.subscribe(listener) do
            yield
          end
        end
      end
    end
  end
end
