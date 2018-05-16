require 'spec_helper'
require 'pact_broker/environments/repository'

module PactBroker
  module Environments
    describe Repository do

      let(:td) { TestDataBuilder.new }

      describe ".find" do

        let(:pacticipant_name) { "test_pacticipant" }
        let(:version_number) { "1.2.3a" }
        let(:environment_name) { "prod" }

        subject { Repository.new }
        let(:options) { {pacticipant_name: pacticipant_name, pacticipant_version_number: version_number, environment_name: environment_name} }
        let(:find_environment) { subject.find options }

        let!(:test_data_builder) do
          TestDataBuilder.new
            .create_pacticipant("wrong_pacticipant")
            .create_version(version_number)
            .create_environment(environment_name) #Environment with wrong pacticipant
            .create_pacticipant(pacticipant_name)
            .create_version("2.0.0")
            .create_environment(environment_name) # Environment with wrong version number
            .create_version(version_number)
            .create_environment("wrong environment") #Environment with wrong name
        end

        context "when the environment exists" do

          before do
            test_data_builder.create_environment(environment_name) # Right environment!
          end

          it "returns the environment" do
            expect(find_environment.name).to eq environment_name
            expect(find_environment.version.number).to eq version_number
            expect(find_environment.version.pacticipant.name).to eq pacticipant_name
            expect(find_environment.created_at).to be_datey
            expect(find_environment.updated_at).to be_datey
          end

          context "when case sensitivity is turned off and a name with different case is used" do
            before do
              allow(PactBroker.configuration).to receive(:use_case_sensitive_resource_names).and_return(false)
            end

            let(:options) { {pacticipant_name: pacticipant_name.upcase, pacticipant_version_number: version_number.upcase, environment_name: environment_name.upcase} }

            it "returns the environment" do
              expect(find_environment).to_not be nil
              expect(find_environment.name).to eq environment_name
            end
          end
        end

        context "when the environment does not exist" do
          it "returns nil" do
            expect(find_environment).to be_nil
          end
        end
      end

      describe "delete_by_version_id" do
        let!(:version) do
          TestDataBuilder.new
            .create_consumer
            .create_provider
            .create_consumer_version("4.5.6")
            .create_consumer_version_environment("prod")
            .create_consumer_version("1.2.3")
            .create_consumer_version_environment("prod")
            .create_consumer_version_environment("foo")
            .and_return(:consumer_version)
        end

        subject { Repository.new.delete_by_version_id(version.id) }

        it "deletes the environment" do
          expect{ subject }.to change { PactBroker::Environments::VersionEnvironment.count }.by(-2)
        end
      end


      describe "find_all_environment_names_for_pacticipant" do
        before do
          td.create_consumer("Foo")
            .create_consumer_version("1")
            .create_consumer_version_environment("prod")
            .create_consumer_version_environment("master")
            .create_consumer_version("2")
            .create_consumer_version_environment("prod")
            .create_consumer_version_environment("dev")
            .create_consumer("Bar")
            .create_consumer_version("1")
            .create_consumer_version_environment("ignore")
        end

        subject { Repository.new.find_all_environment_names_for_pacticipant("Foo") }

        it "returns all the environment names for the pacticipant" do
          expect(subject).to eq ["dev", "master", "prod"]
        end
      end
    end
  end
end
