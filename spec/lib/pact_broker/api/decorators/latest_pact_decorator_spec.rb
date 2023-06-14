require "pact_broker/api/decorators/latest_pact_decorator"

module PactBroker

  module Api

    module Decorators

      describe LatestPactDecorator do

        let(:pact_domain) { TestDataBuilder.new.create_pact_with_hierarchy("Consumer", "1.2.3", "Provider").and_return(:pact) }
        let(:pact) { RepresentablePact.new(pact_domain) }
        let(:base_url) { "http://example.org" }

        subject { JSON.parse LatestPactDecorator.new(pact).to_json(user_options: { base_url: base_url }), symbolize_names: true}

        it "includes the createdAt date" do
          expect(subject[:createdAt]).to_not be_nil
        end

      end
    end
  end
end
