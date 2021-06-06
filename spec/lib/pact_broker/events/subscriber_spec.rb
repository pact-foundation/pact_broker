require "pact_broker/events/subscriber"
require "pact_broker/events/publisher"

module PactBroker
  module Events
    describe "#subscribe" do
      class TestPublisher
        include PactBroker::Events::Publisher

        def broadcast_foo(id)
          broadcast(:foo, id )
        end
      end

      class TestListener
        attr_reader :events

        def initialize
          @events = []
        end

        def foo(params)
          @events << params
        end
      end

      it "allows overlapping subscriptions" do
        listener_1 = TestListener.new
        listener_2 = TestListener.new
        PactBroker::Events.subscribe(listener_1) do
          TestPublisher.new.broadcast_foo(1)
          PactBroker::Events.subscribe(listener_2) do
            TestPublisher.new.broadcast_foo(2)
          end
          TestPublisher.new.broadcast_foo(3)
        end

        expect(listener_1.events).to eq [1, 2, 3]
        expect(listener_2.events).to eq [2]
      end
    end
  end
end
