require 'pact_broker/matrix/service'

module PactBroker
  module Matrix
    describe Service do
      describe "find" do
        subject { Service.find(selectors, options) }

        # Useful for eyeballing the messages to make sure they read nicely
        after do
          # require 'pact_broker/api/decorators/reason_decorator'
          # subject.deployment_status_summary.reasons.each do | reason |
          #   puts reason
          #   puts PactBroker::Api::Decorators::ReasonDecorator.new(reason).to_s
          # end
        end

        let(:options) { {} }


        describe "when deploying a consumer and ignoring a provider" do
          let(:selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1") ]
          end

          let(:options) do
            { latest: true, tag: "prod", latestby: "cvp", ignore_selectors: ignore_selectors }
          end

          let(:ignore_selectors) do
            [ UnresolvedSelector.new(pacticipant_name: "Bar") ]
          end

          describe "with a missing verification from a provider" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_provider_version("2", tag_names: ["prod"])
            end

            it "does allows the consumer to be deployed" do
              expect(subject.deployment_status_summary).to be_deployable
              expect(subject.deployment_status_summary.reasons.first).to be_a(PactBroker::Matrix::IgnoredReason)
              expect(subject.deployment_status_summary.reasons.first.root_reason).to be_a(PactBroker::Matrix::PactNotEverVerifiedByProvider)
            end
          end

          describe "with a failed verification from a provider" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_verification(provider_version: "2", tag_names: ["prod"], success: false)
            end

            it "does allows the consumer to be deployed" do
              expect(subject.deployment_status_summary).to be_deployable
              expect(subject.deployment_status_summary.reasons.first).to be_a(PactBroker::Matrix::IgnoredReason)
              expect(subject.deployment_status_summary.reasons.first.root_reason).to be_a(PactBroker::Matrix::VerificationFailed)
            end

            context "when ignoring the specific provider version" do
              let(:ignore_selectors) do
                [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "2") ]
              end

              it "does allows the consumer to be deployed" do
                expect(subject.deployment_status_summary).to be_deployable
              end
            end

            context "when ignoring a different specific provider version" do
              let(:ignore_selectors) do
                [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "999") ]
              end

              it "does not allow the consumer to be deployed" do
                expect(subject.deployment_status_summary).to_not be_deployable
              end
            end
          end

          describe "when the provider has not been deployed" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_verification(provider_version: "2")
            end

            it "does allows the consumer to be deployed" do
              expect(subject.deployment_status_summary).to be_deployable
              expect(subject.deployment_status_summary.reasons.first).to be_a(PactBroker::Matrix::IgnoredReason)
              expect(subject.deployment_status_summary.reasons.first.root_reason).to be_a(PactBroker::Matrix::PactNotEverVerifiedByProvider)
            end
          end

          describe "when the consumer and provider have been specified" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_verification(provider_version: "2", success: false, tag_names: ["prod"])
            end

            let(:selectors) do
              [
                UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1"),
                UnresolvedSelector.new(pacticipant_name: "Bar", tag: "prod", latest: true)
              ]
            end

            it "does allows the consumer to be deployed" do
              expect(subject.deployment_status_summary).to be_deployable
              expect(subject.deployment_status_summary.reasons.first.root_reason).to be_a(PactBroker::Matrix::VerificationFailed)
            end
          end

          describe "when the consumer and provider have been specified and the provider version specified does not exist" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_verification(provider_version: "2", success: true)
            end

            let(:selectors) do
              [
                UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1"),
                UnresolvedSelector.new(pacticipant_name: "Bar", tag: "prod", latest: true)
              ]
            end

            it "does allows the consumer to be deployed" do
              expect(subject.deployment_status_summary).to be_deployable
              expect(subject.deployment_status_summary.reasons.first.root_reason).to be_a(PactBroker::Matrix::SpecifiedVersionDoesNotExist)
            end
          end
        end
      end
    end
  end
end
