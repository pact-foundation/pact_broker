require 'spec_helper'
require 'pact_broker/groups/service'
require 'pact_broker/index/service'

module PactBroker

  module Groups
    describe Service do

      describe "#find_group_containing" do

        let(:consumer_a) { double('consumer a', name: 'consumer a', id: 1)}
        let(:consumer_b) { double('consumer b', name: 'consumer b', id: 2)}

        let(:provider_x) { double('provider x', name: 'provider x', id: 3)}
        let(:provider_y) { double('provider y', name: 'provider y', id: 4)}

        let(:relationship_1) { Domain::IndexItem.new(consumer_a, provider_x) }
        let(:relationship_2) { Domain::IndexItem.new(consumer_b, provider_y) }

        let(:group_1) { Domain::Group.new(relationship_1) }
        let(:group_2) { Domain::Group.new(relationship_2) }

        let(:relationship_list) { double('relationship list') }
        let(:groups) { [group_1, group_2]}

        subject  { Service.find_group_containing(consumer_b) }

        before do
          allow(PactBroker::Index::Service).to receive(:find_index_items).and_return(relationship_list)
          allow(Relationships::Groupify).to receive(:call).and_return(groups)
        end

        it "retrieves a list of the relationships" do
          allow(Index::Service).to receive(:find_index_items)
          subject
        end

        it "turns the relationships into groups" do
          expect(Relationships::Groupify).to receive(:call).with(relationship_list)
          subject
        end

        it "returns the Group containing the given pacticipant" do
          expect(subject).to be group_2
        end

      end

    end
  end
end