require 'pact_broker/verifications/service'
require 'pact_broker/verifications/repository'
require 'pact_broker/webhooks/execution_configuration'
require 'pact_broker/webhooks/trigger_service'

module PactBroker

  module Verifications
    describe Service do
      before do
        allow(Service).to receive(:logger).and_return(logger)
      end

      let(:logger) { double('logger').as_null_object }

      subject { PactBroker::Verifications::Service }

      describe "#create" do
        before do
          allow(PactBroker::Webhooks::TriggerService).to receive(:trigger_webhooks_for_verification_results_publication)
          allow(webhook_execution_configuration).to receive(:with_webhook_context).and_return(webhook_execution_configuration)
        end

        let(:options) { { webhook_execution_configuration: webhook_execution_configuration } }
        let(:event_context) { { some: "data" } }
        let(:expected_event_context) { { some: "data", provider_version_tags: ["dev"] } }
        let(:webhook_execution_configuration) { instance_double(PactBroker::Webhooks::ExecutionConfiguration) }
        let(:params) { { 'success' => true, 'providerApplicationVersion' => '4.5.6', 'wip' => true, 'testResults' => { 'some' => 'results' }} }
        let(:pact) do
          td.create_pact_with_hierarchy
            .create_provider_version('4.5.6')
            .create_provider_version_tag('dev')
            .and_return(:pact)
        end
        let(:create_verification) { subject.create 3, params, pact, event_context, options }

        it "logs the creation" do
          expect(logger).to receive(:info).with(/.*verification.*3/, payload: {"providerApplicationVersion"=>"4.5.6", "success"=>true, "wip"=>true})
          create_verification
        end

        it "sets the verification attributes" do
          verification = create_verification
          expect(verification.wip).to be true
          expect(verification.success).to be true
          expect(verification.number).to eq 3
          expect(verification.test_results).to eq 'some' => 'results'
        end

        it "sets the pact content for the verification" do
          verification = create_verification
          expect(verification.pact_version_id).to_not be_nil
          expect(verification.pact_version).to_not be_nil
        end

        it "sets the provider version" do
          verification = create_verification
          expect(verification.provider_version).to_not be nil
          expect(verification.provider_version_number).to eq '4.5.6'
        end

        it "sets the provider version tags on the webhook execution configuration" do
          expect(webhook_execution_configuration).to receive(:with_webhook_context).with(provider_version_tags: %w[dev])
          create_verification
        end

        it "invokes the webhooks for the verification" do
          verification = create_verification
          expect(PactBroker::Webhooks::TriggerService).to have_received(:trigger_webhooks_for_verification_results_publication).with(
            pact,
            verification,
            expected_event_context,
            options
          )
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
