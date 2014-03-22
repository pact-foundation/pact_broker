require 'spec_helper'
require 'pact_broker/services/tag_service'

module PactBroker
  module Services
    describe TagService do

      describe ".create" do

        let(:pacticipant_name) { "test_pacticipant" }
        let(:version_number) { "1.2.3" }
        let(:tag_name) { "prod" }

        let(:options) { {pacticipant_name: pacticipant_name, pacticipant_version_number: version_number, tag_name: tag_name}}
        let(:provider_state_builder) { ProviderStateBuilder.new }

        subject { TagService.create(options) }

        # Naughty integration test... didn't seem much point unit testing this

        it "creates the new tag" do
          expect(subject.name).to eq tag_name
          expect(subject.version.number).to eq version_number
          expect(subject.version.pacticipant.name).to eq pacticipant_name
        end

      end

    end
  end
end