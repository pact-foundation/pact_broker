require 'spec_helper'
require 'pact_broker/api/decorators/latest_pact_decorator'

module PactBroker

  module Api

    module Decorators

      describe LatestPactDecorator do

        let(:pact) { RepresentablePact.new(ProviderStateBuilder.new.create_pact_with_hierarchy 'Consumer', '1.2.3', 'Provider') }
        let(:base_url) { 'http://example.org' }

        subject { JSON.parse LatestPactDecorator.new(pact).to_json(user_options: { base_url: base_url }), symbolize_names: true}

        it "includes the createdAt date" do
          expect(subject[:createdAt]).to_not be_nil
        end

        context "when the updatedAt is the same as the createdAt" do
          it "does not include the updatedAt date" do
            expect(subject[:updatedAt]).to be_nil
          end
        end

        context "when the updatedAt is not the same as the createdAt" do
          let(:pact) do
            pact = ProviderStateBuilder.new.create_pact_with_hierarchy 'Consumer', '1.2.3', 'Provider'
            pact.updated_at = pact.created_at + 1
            RepresentablePact.new(pact)
          end

          it "includes the updatedAt date" do
            expect(subject[:updatedAt]).to_not be_nil
          end
        end

      end
    end
  end
end
