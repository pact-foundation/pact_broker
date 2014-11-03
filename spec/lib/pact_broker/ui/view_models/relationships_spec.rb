require 'spec_helper'
require 'pact_broker/ui/view_models/relationships'

module PactBroker
  module UI
    module ViewDomain
      describe Relationships do

        let(:relationship_model_4) { double("PactBroker::Domain::Relationship", consumer_name: "A", provider_name: "X") }
        let(:relationship_model_2) { double("PactBroker::Domain::Relationship", consumer_name: "a", provider_name: "y") }
        let(:relationship_model_3) { double("PactBroker::Domain::Relationship", consumer_name: "A", provider_name: "Z") }
        let(:relationship_model_1) { double("PactBroker::Domain::Relationship", consumer_name: "C", provider_name: "A") }

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

        describe "size_label" do
          context "when there is 1 relationship" do
            subject { Relationships.new([relationship_model_1]) }

            it "returns '1 pact'" do
              expect(subject.size_label).to eq "1 pact"
            end
          end
          context "when there are 0 relationships" do
            subject { Relationships.new([]) }

            it "returns '0 pacts'" do
              expect(subject.size_label).to eq "0 pacts"
            end
          end
          context "when there is more than 1 relationship" do
            subject { Relationships.new([relationship_model_1, relationship_model_1]) }

            it "returns 'x pacts'" do
              expect(subject.size_label).to eq "2 pacts"
            end
          end
        end
      end
    end
  end
end