require 'spec_helper'
require 'pact_broker/functions/groupify'
require 'pact_broker/domain/relationship'

module PactBroker

  module Functions

    describe Groupify do

      describe ".call" do

        let(:consumer_a) { double('consumer a', name: 'consumer a') }
        let(:consumer_b) { double('consumer b', name: 'consumer b') }
        let(:consumer_c) { double('consumer c', name: 'consumer c') }

        let(:consumer_l) { double('consumer l', name: 'consumer l') }
        let(:consumer_m) { double('consumer m', name: 'consumer m') }

        let(:provider_p) { double('provider p', name: 'provider p') }

        let(:provider_x) { double('provider x', name: 'provider x') }
        let(:provider_y) { double('provider y', name: 'provider y') }
        let(:provider_z) { double('provider z', name: 'provider z') }


        let(:relationship_1) { Domain::Relationship.new(consumer_a, provider_x) }
        let(:relationship_4) { Domain::Relationship.new(consumer_a, provider_y) }
        let(:relationship_2) { Domain::Relationship.new(consumer_b, provider_y) }

        let(:relationship_3) { Domain::Relationship.new(consumer_c, provider_z) }


        let(:relationship_5) { Domain::Relationship.new(consumer_l, provider_p) }
        let(:relationship_6) { Domain::Relationship.new(consumer_m, provider_p) }

        let(:relationships) { [relationship_1, relationship_2, relationship_3, relationship_4, relationship_5, relationship_6 ]}

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