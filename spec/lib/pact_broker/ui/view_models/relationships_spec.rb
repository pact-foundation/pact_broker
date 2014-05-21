require 'spec_helper'
require 'pact_broker/ui/view_models/relationships'

module PactBroker
  module UI
    module ViewModels
      describe Relationships do

        let(:relationship_model_4) { double("PactBroker::Models::Relationship", consumer_name: "A", provider_name: "X") }
        let(:relationship_model_2) { double("PactBroker::Models::Relationship", consumer_name: "a", provider_name: "y") }
        let(:relationship_model_3) { double("PactBroker::Models::Relationship", consumer_name: "A", provider_name: "Z") }
        let(:relationship_model_1) { double("PactBroker::Models::Relationship", consumer_name: "C", provider_name: "A") }

        subject { Relationships.new([relationship_model_1, relationship_model_3, relationship_model_4, relationship_model_2]) }

        describe "#each" do

          it "yields the relationships in order" do
            list = []

            subject.each do | relationship_view_model |
              list << [relationship_view_model.consumer_name, relationship_view_model.provider_name]
            end

            expect(list).to eq([["A", "X"],["a","y"],["A","Z"],["C", "A"]])

          end
        end

      end
    end
  end
end