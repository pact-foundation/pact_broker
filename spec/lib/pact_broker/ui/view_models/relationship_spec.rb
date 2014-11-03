require 'spec_helper'
require 'pact_broker/ui/view_models/relationship'

module PactBroker
  module UI
    module ViewDomain
      describe Relationship do

        let(:consumer) { instance_double("PactBroker::Domain::Pacticipant", name: 'Consumer Name')}
        let(:provider) { instance_double("PactBroker::Domain::Pacticipant", name: 'Provider Name')}
        let(:relationship) { PactBroker::Domain::Relationship.new(consumer, provider)}

        subject { Relationship.new(relationship) }

        its(:consumer_name) { should eq 'Consumer Name'}
        its(:provider_name) { should eq 'Provider Name'}
        its(:latest_pact_url) { should eq "/pacts/provider/Provider%20Name/consumer/Consumer%20Name/latest" }
        its(:consumer_group_url) { should eq "/groups/Consumer%20Name" }
        its(:provider_group_url) { should eq "/groups/Provider%20Name" }

        describe "<=>" do

          let(:relationship_model_4) { double("PactBroker::Domain::Relationship", consumer_name: "A", provider_name: "X") }
          let(:relationship_model_2) { double("PactBroker::Domain::Relationship", consumer_name: "a", provider_name: "y") }
          let(:relationship_model_3) { double("PactBroker::Domain::Relationship", consumer_name: "A", provider_name: "Z") }
          let(:relationship_model_1) { double("PactBroker::Domain::Relationship", consumer_name: "C", provider_name: "A") }

          let(:relationship_models) { [relationship_model_1, relationship_model_3, relationship_model_4, relationship_model_2] }
          let(:ordered_view_models) { [relationship_model_4, relationship_model_2, relationship_model_3, relationship_model_1] }

          let(:relationship_view_models) { relationship_models.collect{ |r| Relationship.new(r)} }

          it "sorts by consumer name then provider name" do
            expect(relationship_view_models.sort.collect{ |r| [r.consumer_name, r.provider_name]})
              .to eq([["A", "X"],["a","y"],["A","Z"],["C", "A"]])
          end

        end

      end
    end
  end
end