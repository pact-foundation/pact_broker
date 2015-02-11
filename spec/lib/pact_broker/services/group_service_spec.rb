require 'spec_helper'
require 'pact_broker/services/group_service'

module PactBroker

  module Services
    describe GroupService do


      describe "#find_group_containing" do

        let(:consumer_a) { double('consumer a', name: 'consumer a', id: 1)}
        let(:consumer_b) { double('consumer b', name: 'consumer b', id: 2)}

        let(:provider_x) { double('provider x', name: 'provider x', id: 3)}
        let(:provider_y) { double('provider y', name: 'provider y', id: 4)}

        let(:relationship_1) { Domain::Relationship.new(consumer_a, provider_x) }
        let(:relationship_2) { Domain::Relationship.new(consumer_b, provider_y) }

        let(:group_1) { Domain::Group.new(relationship_1) }
        let(:group_2) { Domain::Group.new(relationship_2) }

        let(:relationship_list) { double('relationship list') }
        let(:groups) { [group_1, group_2]}

        subject  { GroupService.find_group_containing(consumer_b) }

        before do
          allow(PacticipantService).to receive(:find_relationships).and_return(relationship_list)
          allow(Relationships::Groupify).to receive(:call).and_return(groups)
        end

        it "retrieves a list of the relationships" do
          allow(PacticipantService).to receive(:find_relationships)
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