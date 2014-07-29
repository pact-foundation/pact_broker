require 'spec_helper'
require 'pact_broker/services/group_service'

module PactBroker

  module Services
    describe GroupService do


      describe "#find_group_containing" do

        let(:consumer_a) { double('consumer a', name: 'consumer a')}
        let(:consumer_b) { double('consumer b', name: 'consumer b')}

        let(:provider_x) { double('provider x', name: 'provider x')}
        let(:provider_y) { double('provider y', name: 'provider y')}

        let(:relationship_1) { Models::Relationship.new(consumer_a, provider_x) }
        let(:relationship_2) { Models::Relationship.new(consumer_b, provider_y) }

        let(:group_1) { Models::Group.new(relationship_1) }
        let(:group_2) { Models::Group.new(relationship_2) }

        let(:relationship_list) { double('relationship list') }
        let(:groups) { [group_1, group_2]}

        subject  { GroupService.find_group_containing(consumer_b) }

        before do
          allow(PacticipantService).to receive(:find_relationships).and_return(relationship_list)
          allow(Functions::Groupify).to receive(:call).and_return(groups)
        end

        it "retrieves a list of the relationships" do
          allow(PacticipantService).to receive(:find_relationships)
          subject
        end

        it "turns the relationships into groups" do
          expect(Functions::Groupify).to receive(:call).with(relationship_list)
          subject
        end

        it "returns the Group containing the given pacticipant" do
          expect(subject).to be group_2
        end

      end

    end
  end
end