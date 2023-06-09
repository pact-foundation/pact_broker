require "pact_broker/groups/service"

module PactBroker
  module Groups
    describe Service do
      describe "#find_group_containing" do
        before do
          td.create_consumer("app a")
            .create_provider("app x")
            .create_integration
            .create_consumer("app b")
            .create_provider("app y")
            .create_integration
            .use_consumer("app y")
            .create_provider("app z")
            .create_integration
            .use_consumer("app z")
            .use_provider("app y")
            .create_integration
        end

        let(:app_a) { td.find_pacticipant("app a") }
        let(:app_b) { td.find_pacticipant("app b") }

        let(:app_x) { td.find_pacticipant("app x") }
        let(:app_y) { td.find_pacticipant("app y") }
        let(:app_z) { td.find_pacticipant("app z") }

        let(:relationship_1) { Domain::IndexItem.new(app_a, app_x) }
        let(:relationship_2) { Domain::IndexItem.new(app_b, app_y) }
        let(:relationship_3) { Domain::IndexItem.new(app_y, app_z) }
        let(:relationship_3) { Domain::IndexItem.new(app_z, app_y) }

        let(:group_1) { Domain::Group.new(relationship_1) }
        let(:group_2) { Domain::Group.new(relationship_2, relationship_3) }

        subject  { Service.find_group_containing(app_b) }

        it "returns the Group containing the given pacticipant" do
          expect(subject.size).to eq 3
          expect(subject).to include(have_attributes(consumer_name: "app b", provider_name: "app y"))
          expect(subject).to include(have_attributes(consumer_name: "app y", provider_name: "app z"))
          expect(subject).to include(have_attributes(consumer_name: "app z", provider_name: "app y"))
        end

        context "when a max_pacticipants is specified" do
          subject  { Service.find_group_containing(app_b, max_pacticipants: 2) }

          it "returns stops before reaching the end of the group" do
            expect(subject.size).to eq 1
            expect(subject).to include(have_attributes(consumer_name: "app b", provider_name: "app y"))
          end
        end
      end
    end
  end
end