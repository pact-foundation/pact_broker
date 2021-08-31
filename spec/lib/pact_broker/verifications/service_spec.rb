require "pact_broker/verifications/service"
require "pact_broker/verifications/repository"
require "pact_broker/webhooks/execution_configuration"
require "pact_broker/webhooks/trigger_service"

module PactBroker
  module Verifications
    describe Service do
      before do
        allow(Service).to receive(:logger).and_return(logger)
      end

      let(:logger) { double("logger").as_null_object }

      subject { PactBroker::Verifications::Service }

      describe "#create" do
        before do
          allow(Service).to receive(:broadcast)
        end

        let(:event_context) { { some: "data", consumer_version_selectors: [{ foo: "bar" }] } }
        let(:expected_event_context) { { some: "data", provider_version_tags: ["dev"] } }
        let(:params) { { "success" => success, "providerApplicationVersion" => "4.5.6", "wip" => true, "testResults" => { "some" => "results" }} }
        let(:success) { true }
        let(:pact) do
          td.create_pact_with_hierarchy
            .create_provider_version("4.5.6")
            .create_provider_version_tag("dev")
            .and_return(:pact)
        end
        let(:selected_pacts) { [PactBroker::Pacts::SelectedPact.new(pact, PactBroker::Pacts::Selectors.new)]}
        let(:create_verification) { subject.create 3, params, selected_pacts, event_context }

        it "logs the creation" do
          expect(logger).to receive(:info).with(/.*verification.*3/, payload: {"providerApplicationVersion"=>"4.5.6", "success"=>true, "wip"=>true})
          create_verification
        end

        it "sets the verification attributes" do
          verification = create_verification
          expect(verification.wip).to be true
          expect(verification.success).to be true
          expect(verification.number).to eq 3
          expect(verification.test_results).to eq "some" => "results"
          expect(verification.consumer_version_selector_hashes).to eq [{ foo: "bar" }]
          expect(verification.tag_names).to eq ["dev"]
        end

        it "sets the pact content for the verification" do
          verification = create_verification
          expect(verification.pact_version_id).to_not be_nil
          expect(verification.pact_version).to_not be_nil
        end

        it "sets the provider version" do
          verification = create_verification
          expect(verification.provider_version).to_not be nil
          expect(verification.provider_version_number).to eq "4.5.6"
        end

        it "it broadcasts the provider_verification_published event" do
          expect(Service).to receive(:broadcast).with(:provider_verification_published, pact: pact, verification: instance_of(PactBroker::Domain::Verification), event_context: hash_including(provider_version_tags: %w[dev]))
          create_verification
        end

        context "when the verification is successful" do
          it "it broadcasts the provider_verification_succeeded event" do
            expect(Service).to receive(:broadcast).with(:provider_verification_succeeded, pact: pact, verification: instance_of(PactBroker::Domain::Verification), event_context: hash_including(provider_version_tags: %w[dev]))
            create_verification
          end
        end

        context "when the verification is not successful" do
          let(:success) { false }

          it "it broadcasts the provider_verification_failed event" do
            expect(Service).to receive(:broadcast).with(:provider_verification_failed, pact: pact, verification: instance_of(PactBroker::Domain::Verification), event_context: hash_including(provider_version_tags: %w[dev]))
            create_verification
          end
        end

      end

      describe "#calculate_required_verifications_for_pact" do
        subject { Service.calculate_required_verifications_for_pact(pact) }

        context "when there is no verification from the latest version from the main branch" do
          let!(:pact) do
            td.create_consumer("Foo")
              .create_provider("Bar", main_branch: "main")
              .create_provider_version("1", branch: "main")
              .create_consumer_version("1")
              .create_pact
              .and_return(:pact)
          end

          it "returns the required verification for the main branch" do
            expect(subject).to eq [
              RequiredVerification.new(
                provider_version: td.find_version("Bar", "1"),
                provider_version_descriptions: ["latest version from main branch"]
              )
            ]
          end
        end

        context "when there is a verification from the latest version from the main branch" do
          let!(:pact) do
            td.create_consumer("Foo")
              .create_provider("Bar", main_branch: "main")
              .create_provider_version("1", branch: "main")
              .create_consumer_version("1")
              .create_pact
              .create_verification(provider_version: "2", branch: "main")
              .and_return(:pact)
          end

          it "does not return a required verification" do
            expect(subject).to eq []
          end
        end

        context "when there is no verification for a deployed version" do
          let!(:pact) do
            td.create_environment("test")
              .create_consumer("Foo")
              .create_provider("Bar")
              .create_provider_version("1")
              .create_consumer_version("1")
              .create_pact
              .create_deployed_version_for_provider_version
              .and_return(:pact)
          end

          it "returns the required verification for the deployed version" do
            expect(subject).to eq [
              RequiredVerification.new(
                provider_version: td.find_version("Bar", "1"),
                provider_version_descriptions: ["currently deployed version (test)"]
              )
            ]
          end
        end

        context "when there is a verification for a deployed version" do
          let!(:pact) do
            td.create_environment("test")
              .create_consumer("Foo")
              .create_provider("Bar")
              .create_provider_version("1")
              .create_consumer_version("1")
              .create_pact
              .create_verification(provider_version: "1")
              .create_deployed_version_for_provider_version
              .and_return(:pact)
          end

          it "does not return a required verification for the deployed version" do
            expect(subject).to eq []
          end
        end

        context "when there is no verification for a released version" do
          let!(:pact) do
            td.create_environment("test")
              .create_consumer("Foo")
              .create_provider("Bar")
              .create_provider_version("1")
              .create_consumer_version("1")
              .create_pact
              .create_released_version_for_provider_version
              .and_return(:pact)
          end

          it "returns the required verification for the released version" do
            expect(subject).to eq [
              RequiredVerification.new(
                provider_version: td.find_version("Bar", "1"),
                provider_version_descriptions: ["currently released version (test)"]
              )
            ]
          end
        end

        context "when there is a verification for a released version" do
          let!(:pact) do
            td.create_environment("test")
              .create_consumer("Foo")
              .create_provider("Bar")
              .create_provider_version("1")
              .create_consumer_version("1")
              .create_pact
              .create_verification(provider_version: "1")
              .create_released_version_for_provider_version
              .and_return(:pact)
          end

          it "does not return a required verification for the deployed version" do
            expect(subject).to eq []
          end
        end

        context "when the latest version from the main branch is deployed and released and has no verification" do
          let!(:pact) do
            td.create_environment("test")
              .create_consumer("Foo")
              .create_provider("Bar", main_branch: "main")
              .create_provider_version("1", branch: "main")
              .create_consumer_version("1")
              .create_pact
              .create_deployed_version_for_provider_version
              .create_released_version_for_provider_version
              .and_return(:pact)
          end

          it "deduplicates the required versions" do
            expect(subject).to eq [
              RequiredVerification.new(
              provider_version: td.find_version("Bar", "1"),
              provider_version_descriptions: [
                "latest version from main branch",
                "currently deployed version (test)",
                "currently released version (test)"
              ])
            ]
          end
        end
      end

      describe "#errors" do
        let(:params) { {} }

        it "returns errors" do
          expect(subject.errors(params)).to_not be_empty
        end

        it "returns something that responds to :messages" do
          expect(subject.errors(params).messages).to_not be_empty
        end
      end
    end
  end
end
