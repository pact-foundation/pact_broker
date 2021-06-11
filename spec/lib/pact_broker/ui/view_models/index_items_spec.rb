require "spec_helper"
require "pact_broker/ui/view_models/index_items"
require "pact_broker/index/page"

module PactBroker
  module UI
    module ViewDomain
      describe IndexItems do

        let(:relationship_model_4) { double("PactBroker::Domain::IndexItem", consumer_name: "A", provider_name: "X", consumer_version_order: 1) }
        let(:relationship_model_2) { double("PactBroker::Domain::IndexItem", consumer_name: "a", provider_name: "y", consumer_version_order: 2) }
        let(:relationship_model_3) { double("PactBroker::Domain::IndexItem", consumer_name: "A", provider_name: "Z", consumer_version_order: 3) }
        let(:relationship_model_1) { double("PactBroker::Domain::IndexItem", consumer_name: "C", provider_name: "A", consumer_version_order: 4) }

        let(:page) { PactBroker::Index::Page.new([relationship_model_1, relationship_model_3, relationship_model_4, relationship_model_2], 100) }

        subject { IndexItems.new(page) }

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