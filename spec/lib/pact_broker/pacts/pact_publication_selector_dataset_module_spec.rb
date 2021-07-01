require 'pact_broker/pacts/pact_publication_selector_dataset_module'

module PactBroker
  module Pacts
    module PactPublicationSelectorDatasetModule
      describe "#for_provider_and_consumer_version_selector" do

        subject { PactPublication.for_provider_and_consumer_version_selector(provider, consumer_version_selector).all }

        context "for currently deployed versions" do
          before do
            td.create_environment("test")
              .create_consumer("Foo")
              .create_provider("Bar")
              .create_consumer_version("1")
              .create_pact
              .create_deployed_version_for_consumer_version(currently_deployed: false)
              .create_deployed_version_for_consumer_version
              .create_deployed_version_for_consumer_version(target: "customer-1")
          end

          let(:provider) { td.find_pacticipant("Bar") }
          let(:consumer_version_selector) { PactBroker::Pacts::Selector.for_currently_deployed }

          context "when there is a version deployed to multiple targets" do
            it "returns the the same pact for each target" do
              expect(subject.size).to eq 2
              targets = subject.collect{ |p| p.values[:target] }
              expect(targets).to include nil
              expect(targets).to include "customer-1"
            end
          end
        end

        context "for currently supported releases" do
          let(:provider) { td.find_pacticipant("Bar") }
          let(:consumer_version_selector) { PactBroker::Pacts::Selector.for_currently_supported }

          context "when there are releases that are not currently supported" do
            before do
              td.create_environment("test")
                .create_consumer("Foo")
                .create_provider("Bar")
                .create_consumer_version("1")
                .create_pact
                .create_released_version_for_consumer_version(currently_supported: false)
                .create_consumer_version("2")
                .create_pact
                .create_released_version_for_consumer_version
            end

            it "does not include them" do
              expect(subject.size).to eq 1
              expect(subject.first.consumer_version_number).to eq "2"
              expect(subject.first.values[:environment_name]).to eq "test"
            end
          end

          context "when there are versions deployed to multiple environments" do
            before do
              td.create_environment("test")
                .create_environment("prod")
                .create_consumer("Foo")
                .create_provider("Bar")
                .create_consumer_version("1")
                .create_pact
                .create_released_version_for_consumer_version(environment_name: "test")
                .create_released_version_for_consumer_version(environment_name: "test")
                .create_released_version_for_consumer_version(environment_name: "prod")
            end

            context "when there is no environment name specified" do
              it "returns them all" do
                expect(subject.size).to eq 2
                expect(subject.collect { |p | p.values[:environment_name] }.sort).to eq ["prod", "test"]
              end
            end

            context "when an environment name is specified" do
              let(:consumer_version_selector) { PactBroker::Pacts::Selector.for_currently_supported("test") }

              it "returns only the ones from the specified environment" do
                expect(subject.size).to eq 1
                expect(subject.first.values[:environment_name]).to eq "test"
              end
            end
          end
        end
      end
    end
  end
end
