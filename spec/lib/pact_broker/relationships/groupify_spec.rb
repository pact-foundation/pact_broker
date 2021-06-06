require "spec_helper"
require "pact_broker/relationships/groupify"
require "pact_broker/domain/index_item"

module PactBroker

  module Relationships

    describe Groupify do

      describe ".call" do

        let(:consumer_a) { double("consumer a", id: 1, name: "consumer a") }
        let(:consumer_b) { double("consumer b", id: 2, name: "consumer b") }
        let(:consumer_c) { double("consumer c", id: 3, name: "consumer c") }

        let(:consumer_l) { double("consumer l", id: 4, name: "consumer l") }
        let(:consumer_m) { double("consumer m", id: 5, name: "consumer m") }

        let(:provider_p) { double("provider p", id: 6, name: "provider p") }

        let(:provider_x) { double("provider x", id: 7, name: "provider x") }
        let(:provider_y) { double("provider y", id: 8, name: "provider y") }
        let(:provider_z) { double("provider z", id: 9, name: "provider z") }

        let(:relationship_1) { Domain::IndexItem.new(consumer_a, provider_x) }
        let(:relationship_4) { Domain::IndexItem.new(consumer_a, provider_y) }
        let(:relationship_2) { Domain::IndexItem.new(consumer_b, provider_y) }

        let(:relationship_3) { Domain::IndexItem.new(consumer_c, provider_z) }

        let(:relationship_5) { Domain::IndexItem.new(consumer_l, provider_p) }
        let(:relationship_6) { Domain::IndexItem.new(consumer_m, provider_p) }

        let(:relationships) { [relationship_1, relationship_2, relationship_3, relationship_4, relationship_5, relationship_6] }

        it "separates the relationships into isolated groups" do
          groups = Groupify.call(relationships)
          expect(groups[0]).to eq(Domain::Group.new(relationship_1, relationship_4, relationship_2))
          expect(groups[1]).to eq(Domain::Group.new(relationship_3))
          expect(groups[2]).to eq(Domain::Group.new(relationship_5, relationship_6))
        end

      end
    end

  end
end
