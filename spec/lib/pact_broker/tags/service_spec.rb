require "pact_broker/tags/service"

module PactBroker
  module Tags
    describe Service do
      before do
        allow(Service).to receive(:version_service).and_return(version_service)
        allow(Service).to receive(:pacticipant_service).and_return(pacticipant_service)
        allow(version_service).to receive(:maybe_set_version_branch_from_tag)
        allow(pacticipant_service).to receive(:maybe_set_main_branch)
      end
      let(:pacticipant_service) { class_double("PactBroker::Pacticipants::Service").as_stubbed_const }
      let(:version_service) { class_double("PactBroker::Versions::Service").as_stubbed_const }
      let(:tag_reposistory) { instance_double("PactBroker::Tags::Repository", create: double("tag")) }
      let(:pacticipant_name) { "test_pacticipant" }
      let(:version_number) { "1.2.3" }
      let(:tag_name) { "prod" }
      let(:options) { { pacticipant_name: pacticipant_name, pacticipant_version_number: version_number, tag_name: tag_name }}
      let(:use_first_tag_as_branch) { false }

      describe ".create" do
        subject { Service.create(options) }

        it "creates the new tag" do
          expect(subject.name).to eq tag_name
          expect(subject.version.number).to eq version_number
          expect(subject.version.pacticipant.name).to eq pacticipant_name
        end

        it "calls the version_service.maybe_set_version_branch_from_tag before creating the tag" do
          # so that we use the version before the tag is created (we have to detect if there are no tags present)
          allow(Service).to receive(:tag_repository).and_return(tag_reposistory)
          expect(version_service).to receive(:maybe_set_version_branch_from_tag).with(instance_of(PactBroker::Domain::Version), tag_name).ordered
          expect(tag_reposistory).to receive(:create).ordered
          subject
        end

        it "calls the pacticipant_service.maybe_set_main_branch" do
          expect(pacticipant_service).to receive(:maybe_set_main_branch).with(instance_of(PactBroker::Domain::Pacticipant), tag_name)
          subject
        end
      end

      describe "delete" do

        let(:second_pacticipant_name) { "second_test_pacticipant" }
        let(:second_version_number) { "4.5.6" }
        let(:second_options_same_tag_name) { { pacticipant_name: second_pacticipant_name, pacticipant_version_number: second_version_number, tag_name: tag_name }}

        before do
          Service.create(options)
          Service.create(second_options_same_tag_name)
        end

        let(:delete_tag_for_particpant_and_version) { subject.delete second_options_same_tag_name}

        it "deletes the tag for the particpiant and the version" do
          expect{ delete_tag_for_particpant_and_version }.to change{
            PactBroker::Domain::Tag.all.count
          }.by(-1)
        end
      end
    end
  end
end