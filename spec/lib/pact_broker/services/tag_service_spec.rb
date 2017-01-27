require 'spec_helper'
require 'pact_broker/services/tag_service'

module PactBroker
  module Services
    describe TagService do

      let(:pacticipant_name) { "test_pacticipant" }
      let(:version_number) { "1.2.3" }
      let(:tag_name) { "prod" }

      let(:options) { {pacticipant_name: pacticipant_name, pacticipant_version_number: version_number, tag_name: tag_name}}
      let(:provider_state_builder) { ProviderStateBuilder.new }

      describe ".create" do

        subject { TagService.create(options) }

        # Naughty integration test... didn't seem much point unit testing this

        it "creates the new tag" do
          expect(subject.name).to eq tag_name
          expect(subject.version.number).to eq version_number
          expect(subject.version.pacticipant.name).to eq pacticipant_name
        end

      end

      describe "delete" do

        before do
          TagService.create(options)
        end

        let(:delete_tag) { subject.delete "prod" }

        it "deletes the tag" do
          expect{ delete_tag }.to change{
            PactBroker::Domain::Tag.all.count
          }.by(-1)
        end
      end

    end
  end
end