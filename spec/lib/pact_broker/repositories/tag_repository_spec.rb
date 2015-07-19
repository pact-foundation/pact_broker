require 'spec_helper'
require 'pact_broker/repositories/tag_repository'

module PactBroker
  module Repositories
    describe TagRepository do

      describe ".find" do

        let(:pacticipant_name) { "test_pacticipant" }
        let(:version_number) { "1.2.3a" }
        let(:tag_name) { "prod" }

        subject { TagRepository.new }
        let(:options) { {pacticipant_name: pacticipant_name, pacticipant_version_number: version_number, tag_name: tag_name} }
        let(:find_tag) { subject.find options }

        let!(:provider_state_builder) do
          ProviderStateBuilder.new
            .create_pacticipant("wrong_pacticipant")
            .create_version(version_number)
            .create_tag(tag_name) #Tag with wrong pacticipant
            .create_pacticipant(pacticipant_name)
            .create_version("2.0.0")
            .create_tag(tag_name) # Tag with wrong version number
            .create_version(version_number)
            .create_tag("wrong tag") #Tag with wrong name
        end

        context "when the tag exists" do

          before do
            provider_state_builder.create_tag(tag_name) # Right tag!
          end

          it "returns the tag" do
            expect(find_tag.name).to eq tag_name
            expect(find_tag.version.number).to eq version_number
            expect(find_tag.version.pacticipant.name).to eq pacticipant_name
            expect(find_tag.created_at).to be_instance_of(DateTime)
            expect(find_tag.updated_at).to be_instance_of(DateTime)
          end

          context "when case sensitivity is turned off and a name with different case is used" do
            before do
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(false)
            end

            let(:options) { {pacticipant_name: pacticipant_name.upcase, pacticipant_version_number: version_number.upcase, tag_name: tag_name.upcase} }

            it "returns the tag" do
              expect(find_tag).to_not be nil
              expect(find_tag.name).to eq tag_name
            end
          end
        end

        context "when the tag does not exist" do
          it "returns nil" do
            expect(find_tag).to be_nil
          end
        end
      end

    end
  end
end