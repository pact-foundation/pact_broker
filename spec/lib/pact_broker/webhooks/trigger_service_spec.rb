require 'pact_broker/webhooks/trigger_service'

module PactBroker
  module Webhooks
    describe TriggerService do
      let(:pact) { double("pact", pact_version_sha: pact_version_sha, consumer_name: "foo", provider_name: "bar") }
      let(:pact_version_sha) { "111" }
      let(:pact_repository) { double("pact_repository", find_previous_pacts: previous_pacts) }
      let(:pact_service) { class_double("PactBroker::Pacts::Service").as_stubbed_const }
      let(:previous_pact) { double("previous_pact", pact_version_sha: previous_pact_version_sha) }
      let(:previous_pact_version_sha) { "111" }
      let(:previous_pacts) { { untagged: previous_pact } }
      let(:logger) { double('logger').as_null_object }
      let(:event_context) { { some: "data" } }
      let(:webhook_options) { { the: 'options'} }

      before do
        allow(TriggerService).to receive(:pact_repository).and_return(pact_repository)
        allow(TriggerService).to receive(:pact_service).and_return(pact_service)
        allow(TriggerService).to receive(:logger).and_return(logger)
      end

      def find_result_with_message_including(message)
        subject.find { | result | result.message.include?(message) }
      end

      shared_examples_for "triggering a contract_published event" do
        it "triggers a contract_published webhook" do
          expect(TriggerService).to receive(:trigger_webhooks).with(pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_PUBLISHED, event_context, webhook_options)
          subject
        end
      end

      shared_examples_for "triggering a contract_content_changed event" do
        it "triggers a contract_content_changed webhook" do
          expect(TriggerService).to receive(:trigger_webhooks).with(pact, nil, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, event_context, webhook_options)
          subject
        end
      end

      shared_examples_for "not triggering a contract_content_changed event" do
        it "does not trigger a contract_content_changed webhook" do
          expect(TriggerService).to_not receive(:trigger_webhooks).with(anything, anything, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, event_context, anything)
          subject
        end
      end

      describe "#trigger_webhooks_for_new_pact" do
        before do
          allow(TriggerService).to receive(:trigger_webhooks).and_return([])
        end

        subject { TriggerService.trigger_webhooks_for_new_pact(pact, event_context, webhook_options) }

        context "when no previous untagged pact exists" do
          let(:previous_pact) { nil }

          include_examples "triggering a contract_published event"
          include_examples "triggering a contract_content_changed event"

          it "logs the reason why it triggered the contract_content_changed event" do
            expect(logger).to receive(:info).with(/first time untagged pact published/)
            expect(find_result_with_message_including("first time untagged pact published")).to_not be nil
          end
        end

        context "when a previous untagged pact exists and the sha is different" do
          let(:previous_pact_version_sha) { "222" }

          let(:previous_pacts) { { :untagged => previous_pact } }

          include_examples "triggering a contract_published event"
          include_examples "triggering a contract_content_changed event"

          it "logs the reason why it triggered the contract_content_changed event" do
            expect(logger).to receive(:info).with(/pact content has changed since previous untagged version/)
            expect(find_result_with_message_including("pact content has changed since previous untagged version")).to_not be nil
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
            expect(find_result_with_message_including("first time pact published with consumer version tagged dev")).to_not be nil
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
        before do
          allow(TriggerService).to receive(:trigger_webhooks).and_return([])
        end

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
            expect(subject.find { | result | result.message.include?("version 1.2.3 has been updated with new content") }).to_not be nil
          end
        end

        context "when the pact version sha of the previous revision is not different, not sure if we'll even get this far if it hasn't changed, but just in case..." do
          include_examples "triggering a contract_published event"
          include_examples "not triggering a contract_content_changed event"
        end
      end

      describe "#trigger_webhooks_for_verification_results_publication" do
        before do
          allow(TriggerService).to receive(:trigger_webhooks).and_return([])
        end

        before do
          allow(pact_service).to receive(:find_pact).and_return(pact_for_consumer_version_1, pact_for_consumer_version_2)
          # allow(pact_service).to receive(:find_pact).with(hash_including(consumer_version_number: "2")).and_return(pact_for_consumer_version_2)
        end
        let(:verification) { double("verification", success: success) }
        let(:success) { true }
        # See lib/pact_broker/pacts/metadata.rb build_metadata_for_pact_for_verification
        let(:selector_1) { { latest: true, consumer_version_number: "1", tag: "prod" } }
        let(:selector_2) { { latest: true, consumer_version_number: "1", tag: "main" } }
        let(:selector_3) { { latest: true, consumer_version_number: "2", tag: "feat/2" } }
        let(:event_context) do
          {
            consumer_version_selectors: [selector_1, selector_2, selector_3],
            other: "foo"
          }
        end
        let(:expected_event_context_1) { { consumer_version_number: "1", consumer_version_tags: ["prod", "main"], other: "foo" } }
        let(:expected_event_context_2) { { consumer_version_number: "2", consumer_version_tags: ["feat/2"], other: "foo" } }
        let(:pact_for_consumer_version_1) { double('pact_for_consumer_version_1') }
        let(:pact_for_consumer_version_2) { double('pact_for_consumer_version_2') }

        subject { TriggerService.trigger_webhooks_for_verification_results_publication(pact, verification, event_context, webhook_options) }

        it "find the pact publication for each consumer version number" do
          expect(pact_service).to receive(:find_pact).with(hash_including(consumer_version_number: "1")).and_return(pact_for_consumer_version_1)
          expect(pact_service).to receive(:find_pact).with(hash_including(consumer_version_number: "2")).and_return(pact_for_consumer_version_2)
          subject
        end

        context "when the verification is successful" do
          context "when there are consumer_version_selectors in the event_context" do
            it "triggers a provider_verification_succeeded webhook for each consumer version (ie. commit)" do
              expect(TriggerService).to receive(:trigger_webhooks).with(pact_for_consumer_version_1, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_SUCCEEDED, expected_event_context_1, webhook_options)
              expect(TriggerService).to receive(:trigger_webhooks).with(pact_for_consumer_version_2, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_SUCCEEDED, expected_event_context_2, webhook_options)
              subject
            end

            it "triggers a provider_verification_published webhook for each consumer version (ie. commit)" do
              expect(TriggerService).to receive(:trigger_webhooks).with(pact_for_consumer_version_1, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED, expected_event_context_1, webhook_options)
              expect(TriggerService).to receive(:trigger_webhooks).with(pact_for_consumer_version_2, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED, expected_event_context_2, webhook_options)
              subject
            end
          end

          context "when there are no consumer_version_selectors" do
            let(:event_context) { { some: "data" } }

            it "passes through the event context" do
              expect(TriggerService).to receive(:trigger_webhooks).with(pact, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_SUCCEEDED, event_context, webhook_options)
              expect(TriggerService).to receive(:trigger_webhooks).with(pact, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED, event_context, webhook_options)
              subject
            end
          end
        end

        context "when the verification is not successful" do
          let(:success) { false }

          context "when there are consumer_version_selectors in the event_context" do
            it "triggers a provider_verification_failed webhook for each consumer version (ie. commit)" do
              expect(TriggerService).to receive(:trigger_webhooks).with(pact_for_consumer_version_1, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_FAILED, expected_event_context_1, webhook_options)
              expect(TriggerService).to receive(:trigger_webhooks).with(pact_for_consumer_version_2, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_FAILED, expected_event_context_2, webhook_options)
              subject
            end

            it "triggeres a provider_verification_published webhook for each consumer version (ie. commit)" do
              expect(TriggerService).to receive(:trigger_webhooks).with(pact_for_consumer_version_1, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED, expected_event_context_1, webhook_options)
              expect(TriggerService).to receive(:trigger_webhooks).with(pact_for_consumer_version_2, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED, expected_event_context_2, webhook_options)
              subject
            end
          end

          context "when there are no consumer_version_selectors" do
            let(:event_context) { { some: "data" } }

            it "passes through the event context" do
              expect(TriggerService).to receive(:trigger_webhooks).with(pact, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_FAILED, event_context, webhook_options)
              expect(TriggerService).to receive(:trigger_webhooks).with(pact, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED, event_context, webhook_options)
              subject
            end
          end
        end
      end
    end

    describe TriggerService do

      describe ".trigger_webhooks" do
        before do
          allow(TriggerService).to receive(:logger).and_return(logger)
        end
        let(:logger) { double('logger').as_null_object }
        let(:verification) { instance_double(PactBroker::Domain::Verification)}
        let(:pact) { instance_double(PactBroker::Domain::Pact, consumer: consumer, provider: provider, consumer_version: consumer_version)}
        let(:consumer_version) { PactBroker::Domain::Version.new(number: '1.2.3') }
        let(:consumer) { PactBroker::Domain::Pacticipant.new(name: 'Consumer') }
        let(:provider) { PactBroker::Domain::Pacticipant.new(name: 'Provider') }
        let(:webhooks) { [webhook]}
        let(:webhook) do
          instance_double(PactBroker::Domain::Webhook, description: 'description', uuid: '1244', expand_currently_deployed_provider_versions?: expand_currently_deployed)
        end
        let(:expand_currently_deployed) { false }
        let(:triggered_webhook) { instance_double(PactBroker::Webhooks::TriggeredWebhook) }
        let(:webhook_execution_configuration) { double('webhook_execution_configuration', webhook_context: webhook_context) }
        let(:webhook_context) { { base_url: "http://example.org" } }
        let(:event_context) { { some: "data" } }
        let(:expected_event_context) { { some: "data", event_name: PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, base_url: "http://example.org" } }
        let(:options) do
          { database_connector: double('database_connector'),
            webhook_execution_configuration: webhook_execution_configuration,
            logging_options: {}
          }
        end

        before do
          allow(webhook_execution_configuration).to receive(:with_webhook_context).and_return(webhook_execution_configuration)
          allow_any_instance_of(PactBroker::Webhooks::Repository).to receive(:find_by_consumer_and_or_provider_and_event_name).and_return(webhooks)
          allow_any_instance_of(PactBroker::Webhooks::Repository).to receive(:create_triggered_webhook).and_return(triggered_webhook)
          allow(Job).to receive(:perform_in)
        end

        subject { TriggerService.trigger_webhooks(pact, verification, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, event_context, options) }

        it "finds the webhooks" do
          expect_any_instance_of(PactBroker::Webhooks::Repository).to receive(:find_by_consumer_and_or_provider_and_event_name).with(consumer, provider, PactBroker::Webhooks::WebhookEvent::DEFAULT_EVENT_NAME)
          subject
        end

        context "when webhooks are found" do
          it "schedules the webhook" do
            expect(TriggerService).to receive(:run_webhooks_later).with(webhooks, pact, verification, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, expected_event_context, options)
            subject
          end

          it "merges the event name in the options" do
            expect(webhook_execution_configuration).to receive(:with_webhook_context).with(event_name: PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED)
            subject
          end

          context "when there should be a webhook triggered for each currently deployed version" do
            before do
              allow(TriggerService).to receive(:deployed_version_service).and_return(deployed_version_service)
              allow(deployed_version_service).to receive(:find_currently_deployed_versions_for_pacticipant).and_return(currently_deployed_versions)
            end
            let(:expand_currently_deployed) { true }
            let(:deployed_version_service) { class_double("PactBroker::Deployments::DeployedVersionService").as_stubbed_const }
            let(:currently_deployed_version_1) { instance_double("PactBroker::Deployments::DeployedVersion", version_number: "1") }
            let(:currently_deployed_version_2) { instance_double("PactBroker::Deployments::DeployedVersion", version_number: "2") }
            let(:currently_deployed_versions) { [currently_deployed_version_1, currently_deployed_version_2] }

            it "schedules a triggered webhook for each currently deployed version" do
              expect(TriggerService).to receive(:schedule_webhook).with(webhook, pact, verification, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, expected_event_context.merge(currently_deployed_provider_version_number: "1"), options, 0)
              expect(TriggerService).to receive(:schedule_webhook).with(webhook, pact, verification, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, expected_event_context.merge(currently_deployed_provider_version_number: "2"), options, 5)
              subject
            end

            context "when the same version is deployed to multiple environments" do
              let(:currently_deployed_version_2) { instance_double("PactBroker::Deployments::DeployedVersion", version_number: "1") }

              it "only triggers one webhook" do
                expect(TriggerService).to receive(:schedule_webhook).with(anything, anything, anything, anything, expected_event_context.merge(currently_deployed_provider_version_number: "1"), anything, 0)
                subject
              end
            end
          end
        end

        context "when no webhooks are found" do
          before do
            allow(TriggerService).to receive(:logger).and_return(logger)
          end
          let(:logger) { double('logger').as_null_object }
          let(:webhooks) { [] }
          it "does nothing" do
            expect(TriggerService).to_not receive(:run_webhooks_later)
            subject
          end

          it "logs that no webhook was found" do
            expect(logger).to receive(:info).with(/No enabled webhooks found/)
            subject
          end
        end

        context "when there is a scheduling error", job: true do
          before do
            allow(TriggerService).to receive(:logger).and_return(logger)
          end
          let(:logger) { double('logger').as_null_object }
          before do
            allow(Job).to receive(:perform_in).and_raise("an error")
          end

          it "logs the error" do
            allow(TriggerService.logger).to receive(:warn)
            expect(TriggerService.logger).to receive(:warn).with(/Error scheduling/, StandardError)
            subject
          end
        end
      end

      describe ".test_execution" do
        let(:webhook) do
          instance_double(PactBroker::Domain::Webhook,
            trigger_on_provider_verification_published?: trigger_on_verification,
            consumer_name: 'consumer',
            provider_name: 'provider',
            execute: result
          )
        end
        let(:pact) { instance_double(PactBroker::Domain::Pact) }
        let(:verification) { instance_double(PactBroker::Domain::Verification) }
        let(:trigger_on_verification) { false }
        let(:result) { double('result') }
        let(:execution_configuration) do
          instance_double(PactBroker::Webhooks::ExecutionConfiguration, to_hash: execution_configuration_hash)
        end
        let(:execution_configuration_hash) { { the: 'options' } }
        let(:event_context) { { some: "data" } }

        before do
          allow(PactBroker::Pacts::Service).to receive(:search_for_latest_pact).and_return(pact)
          allow(PactBroker::Verifications::Service).to receive(:search_for_latest).and_return(verification)
          allow(PactBroker.configuration).to receive(:show_webhook_response?).and_return('foo')
          allow(execution_configuration).to receive(:with_failure_log_message).and_return(execution_configuration)
        end

        subject { TriggerService.test_execution(webhook, event_context, execution_configuration) }

        it "searches for the latest matching pact" do
          expect(PactBroker::Pacts::Service).to receive(:search_for_latest_pact).with(consumer_name: 'consumer', provider_name: 'provider')
          subject
        end

        it "returns the result" do
          expect(subject).to be result
        end

        context "when the trigger is not for a verification" do
          it "executes the webhook with the pact" do
            expect(webhook).to receive(:execute).with(pact, nil, event_context.merge(event_name: "test"), execution_configuration_hash)
            subject
          end
        end

        context "when a pact cannot be found" do
          let(:pact) { nil }

          it "executes the webhook with a placeholder pact" do
            expect(webhook).to receive(:execute).with(an_instance_of(PactBroker::Pacts::PlaceholderPact), anything, anything, anything)
            subject
          end
        end

        context "when the trigger is for a verification publication" do
          let(:trigger_on_verification) { true }

          it "searches for the latest matching verification" do
            expect(PactBroker::Verifications::Service).to receive(:search_for_latest).with('consumer', 'provider')
            subject
          end

          it "executes the webhook with the pact and the verification" do
            expect(webhook).to receive(:execute).with(pact, verification, event_context.merge(event_name: "test"), execution_configuration_hash)
            subject
          end

          context "when a verification cannot be found" do
            let(:verification) { nil }

            it "executes the webhook with a placeholder verification" do
              expect(webhook).to receive(:execute).with(anything, an_instance_of(PactBroker::Verifications::PlaceholderVerification), anything, anything)
              subject
            end
          end
        end
      end

      describe ".trigger_webhooks integration test", job: true do
        let!(:http_request) do
          stub_request(:get, "http://example.org").
            to_return(:status => 200)
        end

        let(:events) { [{ name: PactBroker::Webhooks::WebhookEvent::DEFAULT_EVENT_NAME }] }
        let(:webhook_execution_configuration) do
          PactBroker::Webhooks::ExecutionConfiguration.new
            .with_webhook_context(base_url: 'http://example.org')
            .with_show_response(true)
        end
        let(:event_context) { { some: "data", base_url: "http://example.org" }}
        let(:options) do
          {
            database_connector: database_connector,
            webhook_execution_configuration: webhook_execution_configuration
          }
        end
        let(:logging_options) { { show_response: true } }
        let(:database_connector) { ->(&block) { block.call } }
        let(:pact) do
          td.create_consumer
            .create_provider
            .create_consumer_version
            .create_pact
            .create_verification
            .create_webhook(method: 'GET', url: 'http://example.org', events: events)
            .and_return(:pact)
        end

        subject { PactBroker::Webhooks::TriggerService.trigger_webhooks(pact, td.verification, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, event_context, options) }

        it "executes the HTTP request of the webhook" do
          subject
          expect(http_request).to have_been_made
        end

        it "executes the webhook with the correct options" do
          expect_any_instance_of(PactBroker::Domain::WebhookRequest).to receive(:execute).and_call_original
          subject
        end

        it "saves the triggered webhook" do
          expect { subject }.to change { PactBroker::Webhooks::TriggeredWebhook.count }.by(1)
        end

        it "saves the execution" do
          expect { subject }.to change { PactBroker::Webhooks::Execution.count }.by(1)
        end

        it "marks the triggered webhook as a success" do
          subject
          expect(TriggeredWebhook.first.status).to eq TriggeredWebhook::STATUS_SUCCESS
        end
      end
    end
  end
end
