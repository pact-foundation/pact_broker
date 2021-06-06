require "pact_broker/matrix/service"

module PactBroker
  module Matrix
    describe Service do
      describe "find with environments" do
        subject { Service.find(selectors, options) }

        # Useful for eyeballing the messages to make sure they read nicely
        # after do
        #   require 'pact_broker/api/decorators/reason_decorator'
        #   subject.deployment_status_summary.reasons.each do | reason |
        #     puts reason
        #     puts PactBroker::Api::Decorators::ReasonDecorator.new(reason).to_s
        #   end
        # end

        context "when there is a successful verification between the provider in test environment and the consumer to be deployed" do
          before do
            td.create_environment("test")
              .create_pact_with_verification("Foo", "1", "Bar", "2")
              .create_deployed_version_for_provider_version
              .create_verification(provider_version: "3", number: 2, success: false)
          end

          let(:selectors) do
            [
              UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1"),
            ]
          end

          let(:options) { { latestby: "cvp", environment_name: "test" } }

          it "allows the consumer to be deployed" do
            expect(subject.deployment_status_summary).to be_deployable
          end
        end

        context "when there is an unsuccessful verification between the provider in test environment and the consumer to be deployed" do
          before do
            td.create_environment("test")
              .create_pact_with_verification("Foo", "1", "Bar", "2", false)
              .create_deployed_version_for_provider_version
              .create_verification(provider_version: "3", number: 3, success: true)
          end

          let(:selectors) do
            [
              UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1"),
            ]
          end

          let(:options) { { latestby: "cvp", environment_name: "test" } }

          it "does not allow the consumer to be deployed" do
            expect(subject.deployment_status_summary).to_not be_deployable
          end
        end

        context "when the provider has not been deployed to the given environment" do
          before do
            td.create_environment("test")
              .create_pact_with_verification("Foo", "1", "Bar", "2")
          end

          let(:selectors) do
            [
              UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1"),
            ]
          end

          let(:options) { { latestby: "cvp", environment_name: "test" } }

          it "does not allow the consumer to be deployed" do
            expect(subject.deployment_status_summary).to_not be_deployable
          end
        end

        context "when the consumer has not been deployed to the given environment" do
          before do
            td.create_environment("test")
              .create_pact_with_verification("Foo", "1", "Bar", "2")
          end

          let(:selectors) do
            [
              UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2"),
            ]
          end

          let(:options) { { latestby: "cvp", environment_name: "test" } }

          it "allows the provider to be deployed" do
            expect(subject.deployment_status_summary).to be_deployable
          end
        end

        describe "when deploying a version of a provider with multiple versions of a consumer in production" do
          before do
            td.create_environment("prod")
              .create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_deployed_version_for_consumer_version(environment_name: "prod", target: "1")
              .create_verification(provider_version: "10")
              .create_consumer_version("2")
              .create_pact
              .create_deployed_version_for_consumer_version(environment_name: "prod", target: "2")
          end

          let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "10") ]}
          let(:options) { { environment_name: "prod" } }

          it "knows that there are multiple versions of the consumer in production" do
            subject
            expect(subject.resolved_selectors.select { |s| s.pacticipant_name == "Bar" }.collect(&:one_of_many?)).to eq [false]
            expect(subject.resolved_selectors.select { |s| s.pacticipant_name == "Foo" }.collect(&:one_of_many?)).to eq [true, true]
          end

          context "when a verification for the latest prod version is missing" do
            it "does not allow the provider to be deployed" do
              expect(subject.deployment_status_summary).to_not be_deployable
            end
          end

          context "when there is a successful verification for every prod version of the consumer" do
            before do
              td.create_verification(provider_version: "10")
            end

            it "does allow the provider to be deployed" do
              expect(subject.deployment_status_summary).to be_deployable
            end
          end
        end

        describe "when deploying a version of a consumer with multiple versions of a provider in production" do
          before do
            td.create_environment("prod")
              .create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_verification(provider_version: "10")
              .create_deployed_version_for_provider_version(environment_name: "prod", target: "1")
              .create_consumer_version("2")
              .create_pact
              .create_provider_version("11")
              .create_deployed_version_for_provider_version(environment_name: "prod", target: "2")
          end

          let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "2") ]}
          let(:options) { { environment_name: "prod" } }

          it "knows that there are multiple versions of the provider in production" do
            subject
            expect(subject.resolved_selectors.select { |s| s.pacticipant_name == "Foo" }.collect(&:one_of_many?)).to eq [false]
            expect(subject.resolved_selectors.select { |s| s.pacticipant_name == "Bar" }.collect(&:one_of_many?)).to eq [true, true]
          end

          context "when a verification for the latest prod version is missing" do
            it "does not allow the consumer to be deployed" do
              expect(subject.deployment_status_summary).to_not be_deployable
            end
          end

          context "when there is a successful verification for every prod version of the consumer" do
            before do
              td.create_verification(provider_version: "11")
            end

            it "does allow the consumer to be deployed" do
              expect(subject.deployment_status_summary).to be_deployable
            end
          end
        end
      end
    end
  end
end
