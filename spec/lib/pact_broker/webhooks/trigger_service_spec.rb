require 'pact_broker/webhooks/trigger_service'

module PactBroker
  module Webhooks
    describe TriggerService do
      let(:pact) { double("pact", pact_version_sha: pact_version_sha) }
      let(:pact_version_sha) { "111" }
      let(:pact_repository) { double("pact_repository", find_previous_pacts: previous_pacts) }
      let(:webhook_service) { double("webhook_service", trigger_webhooks: nil) }
      let(:previous_pact) { double("previous_pact", pact_version_sha: previous_pact_version_sha) }
      let(:previous_pact_version_sha) { "111" }
      let(:previous_pacts) { { untagged: previous_pact } }
      let(:logger) { double('logger').as_null_object }
      let(:event_context) { { some: "data" } }
      let(:webhook_options) { { the: 'options'} }

      before do
        allow(TriggerService).to receive(:pact_repository).and_return(pact_repository)
        allow(TriggerService).to receive(:webhook_service).and_return(webhook_service)
        allow(TriggerService).to receive(:logger).and_return(logger)
      end

      shared_examples_for "triggering a contract_published event" do
        it "triggers a contract_published webhook" do
          expect(webhook_service).to receive(:trigger_webhooks).with(pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_PUBLISHED, event_context, webhook_options)
          subject
        end
      end

      shared_examples_for "triggering a contract_content_changed event" do
        it "triggers a contract_content_changed webhook" do
          expect(webhook_service).to receive(:trigger_webhooks).with(pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, event_context, webhook_options)
          subject
        end
      end

      shared_examples_for "not triggering a contract_content_changed event" do
        it "does not trigger a contract_content_changed webhook" do
          expect(webhook_service).to_not receive(:trigger_webhooks).with(anything, anything, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, event_context, anything)
          subject
        end
      end

      describe "#trigger_webhooks_for_new_pact" do
        subject { TriggerService.trigger_webhooks_for_new_pact(pact, event_context, webhook_options) }

        context "when no previous untagged pact exists" do
          let(:previous_pact) { nil }

          include_examples "triggering a contract_published event"
          include_examples "triggering a contract_content_changed event"

          it "logs the reason why it triggered the contract_content_changed event" do
            expect(logger).to receive(:info).with(/first time untagged pact published/)
            subject
          end
        end

        context "when a previous untagged pact exists and the sha is different" do
          let(:previous_pact_version_sha) { "222" }

          let(:previous_pacts) { { :untagged => previous_pact } }

          include_examples "triggering a contract_published event"
          include_examples "triggering a contract_content_changed event"

          it "logs the reason why it triggered the contract_content_changed event" do
            expect(logger).to receive(:info).with(/pact content has changed since previous untagged version/)
            subject
          end
        end

        context "when a previous untagged pact exists and the sha is the same" do
          let(:previous_pact_version_sha) { pact_version_sha }

          let(:previous_pacts) { { :untagged => previous_pact } }

          include_examples "triggering a contract_published event"
          include_examples "not triggering a contract_content_changed event"
        end

        context "when no previous pact with a given tag exists" do
          let(:previous_pact) { nil }
          let(:previous_pacts) { { "dev" => previous_pact } }

          include_examples "triggering a contract_published event"
          include_examples "triggering a contract_content_changed event"

          it "logs the reason why it triggered the contract_content_changed event" do
            expect(logger).to receive(:info).with(/first time pact published with consumer version tagged dev/)
            subject
          end
        end

        context "when a previous pact with a given tag exists and the sha is different" do
          let(:previous_pact_version_sha) { "222" }
          let(:previous_pacts) { { "dev" => previous_pact } }

          include_examples "triggering a contract_published event"
          include_examples "triggering a contract_content_changed event"
        end

        context "when a previous pact with a given tag exists and the sha is the same" do
          let(:previous_pact_version_sha) { pact_version_sha }
          let(:previous_pacts) { { "dev" => previous_pact } }

          include_examples "triggering a contract_published event"
          include_examples "not triggering a contract_content_changed event"
        end
      end

      describe "#trigger_webhooks_for_updated_pact" do
        let(:existing_pact) do
          double('existing_pact',
            pact_version_sha: existing_pact_version_sha,
            consumer_version_number: "1.2.3"
          )
        end
        let(:existing_pact_version_sha) { pact_version_sha }

        subject { TriggerService.trigger_webhooks_for_updated_pact(existing_pact, pact, event_context, webhook_options) }

        context "when the pact version sha of the previous revision is different" do
          let(:existing_pact_version_sha) { "456" }

          include_examples "triggering a contract_published event"
          include_examples "triggering a contract_content_changed event"

          it "logs the reason why it triggered the contract_content_changed event" do
            expect(logger).to receive(:info).with(/version 1.2.3 has been updated with new content/)
            subject
          end
        end

        context "when the pact version sha of the previous revision is not different, not sure if we'll even get this far if it hasn't changed, but just in case..." do
          include_examples "triggering a contract_published event"
          include_examples "not triggering a contract_content_changed event"
        end
      end

      describe "#trigger_webhooks_for_verification_results_publication" do
        let(:verification) { double("verification", success: success) }
        let(:success) { true }

        subject { TriggerService.trigger_webhooks_for_verification_results_publication(pact, verification, event_context, webhook_options) }

        context "when the verification is successful" do
          it "triggers a provider_verification_succeeded webhook" do
            expect(webhook_service).to receive(:trigger_webhooks).with(pact, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_SUCCEEDED, event_context, webhook_options)
            subject
          end

          it "triggers a provider_verification_published webhook" do
            expect(webhook_service).to receive(:trigger_webhooks).with(pact, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED, event_context, webhook_options)
            subject
          end
        end

        context "when the verification is not successful" do
          let(:success) { false }

          it "triggers a provider_verification_failed webhook" do
            expect(webhook_service).to receive(:trigger_webhooks).with(pact, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_FAILED, event_context, webhook_options)
            subject
          end

          it "triggeres a provider_verification_published webhook" do
            expect(webhook_service).to receive(:trigger_webhooks).with(pact, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED, event_context, webhook_options)
            subject
          end
        end
      end
    end
  end
end
