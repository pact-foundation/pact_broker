require 'spec_helper'
require 'pact_broker/environments/service'

module PactBroker
  module Environments
    describe Service do

      let(:pacticipant_name) { "test_pacticipant" }
      let(:version_number) { "1.2.3" }
      let(:environment_name) { "prod" }

      let(:options) { {pacticipant_name: pacticipant_name, pacticipant_version_number: version_number, environment_name: environment_name}}
      let(:test_data_builder) { TestDataBuilder.new }

      describe ".create" do

        subject { Service.create(options) }

        # Naughty integration test... didn't seem much point unit testing this

        it "creates the new environment" do
          expect(subject.name).to eq environment_name
          expect(subject.version.number).to eq version_number
          expect(subject.version.pacticipant.name).to eq pacticipant_name
        end

      end

      describe "delete" do

        let(:second_pacticipant_name) { "second_test_pacticipant" }
        let(:second_version_number) { "4.5.6" }
        let(:second_options_same_environment_name) { {pacticipant_name: second_pacticipant_name, pacticipant_version_number: second_version_number, environment_name: environment_name}}

        before do
          Service.create(options)
          Service.create(second_options_same_environment_name)
        end

        let(:delete_environment_for_particpant_and_version) { subject.delete second_options_same_environment_name}

        it "deletes the environment for the particpiant and the version" do
          expect{ delete_environment_for_particpant_and_version }.to change{
            PactBroker::Environments::Environment.all.count
          }.by(-1)
        end
      end
    end
  end
end