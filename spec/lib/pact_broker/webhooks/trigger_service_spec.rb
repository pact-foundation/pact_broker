require "pact_broker/webhooks/trigger_service"

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
      let(:logger) { double("logger").as_null_object }
      let(:event_context) { { some: "data" } }
      let(:webhook_options) { { the: "options"} }

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
    end

    describe TriggerService do
      describe ".create_triggered_webhooks_for_event" do
        before do
          allow(TriggerService).to receive(:webhook_repository).and_return(webhook_repository)
          allow(TriggerService).to receive(:logger).and_return(logger)
          allow(TriggerService).to receive(:pact_service).and_return(pact_service)
        end
        let(:pact_service) { class_double("PactBroker::Pacts::Service").as_stubbed_const }
        let(:logger) { double("logger").as_null_object }
        let(:verification) { instance_double(PactBroker::Domain::Verification)}
        let(:pact) { instance_double(PactBroker::Domain::Pact, consumer: consumer, provider: provider, consumer_version: consumer_version)}
        let(:consumer_version) { PactBroker::Domain::Version.new(number: "1.2.3") }
        let(:consumer) { PactBroker::Domain::Pacticipant.new(name: "Consumer") }
        let(:provider) { PactBroker::Domain::Pacticipant.new(name: "Provider") }
        let(:webhooks) { [webhook]}
        let(:webhook) do
          instance_double(PactBroker::Domain::Webhook,
            description: "description",
            uuid: "1244",
            expand_currently_deployed_provider_versions?: expand_currently_deployed
          )
        end
        let(:expand_currently_deployed) { false }
        let(:trigger_on_contract_requiring_verification_published) { false }
        let(:triggered_webhook) { instance_double(PactBroker::Webhooks::TriggeredWebhook) }
        let(:event_name) { PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED }
        let(:event_context) { { some: "data" } }
        let(:expected_event_context) { { some: "data", event_name: event_name } }
        let(:webhook_repository) { instance_double(Repository, create_triggered_webhook: triggered_webhook, find_webhooks_to_trigger: webhooks) }

        subject { TriggerService.create_triggered_webhooks_for_event(pact, verification, event_name, event_context) }

        it "finds the webhooks" do
          expect(webhook_repository).to receive(:find_webhooks_to_trigger).with(consumer: consumer, provider: provider, event_name: PactBroker::Webhooks::WebhookEvent::DEFAULT_EVENT_NAME)
          subject
        end

        context "when webhooks are found" do
          it "merges the event name in the webhook context" do
            expect(webhook_repository).to receive(:create_triggered_webhook).with(anything, anything, anything, anything, anything, anything, hash_including(event_name: PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED))
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

            it "creates a triggered webhook for each currently deployed version" do
              expect(webhook_repository).to receive(:create_triggered_webhook).with(anything, webhook, pact, verification, TriggerService::RESOURCE_CREATION, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, expected_event_context.merge(currently_deployed_provider_version_number: "1"))
              expect(webhook_repository).to receive(:create_triggered_webhook).with(anything, webhook, pact, verification, TriggerService::RESOURCE_CREATION, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, expected_event_context.merge(currently_deployed_provider_version_number: "2"))
              subject
            end

            context "when the same version is deployed to multiple environments" do
              let(:currently_deployed_version_2) { instance_double("PactBroker::Deployments::DeployedVersion", version_number: "1") }

              it "only creates one triggered webhook" do
                expect(webhook_repository).to receive(:create_triggered_webhook).with(anything, anything, anything, anything, anything, anything, expected_event_context.merge(currently_deployed_provider_version_number: "1"))
                subject
              end
            end
          end

          context "when the event is contract_requiring_verification_published" do
            before do
              allow(TriggerService).to receive(:verification_service).and_return(verification_service)
              allow(verification_service).to receive(:calculate_required_verifications_for_pact).and_return(required_verifications)
            end

            let(:event_name) { PactBroker::Webhooks::WebhookEvent::CONTRACT_REQUIRING_VERIFICATION_PUBLISHED }
            let(:verification_service) { class_double("PactBroker::Verifications::Service").as_stubbed_const }
            let(:required_verifications) { [required_verification] }
            let(:required_verification) do
              instance_double("PactBroker::Verifications::RequiredVerification",
                provider_version: double("version", number: "1"),
                provider_version_descriptions: ["foo"]
              )
            end

            it "creates a triggered webhook for each required verification" do
              expect(webhook_repository).to receive(:create_triggered_webhook).with(
                anything,
                webhook,
                pact,
                verification,
                TriggerService::RESOURCE_CREATION,
                PactBroker::Webhooks::WebhookEvent::CONTRACT_REQUIRING_VERIFICATION_PUBLISHED,
                expected_event_context.merge(provider_version_number: "1", provider_version_descriptions: ["foo"])
              )
              subject
            end

            it "returns the triggered webhooks" do
              expect(subject.size).to eq 1
            end

            context "when there are no required verifications" do
              let(:required_verifications) { [] }

              it "does not create any triggered webhooks" do
                expect(webhook_repository).to_not receive(:create_triggered_webhook)
                subject
              end

              it "returns an empty array" do
                expect(subject).to eq []
              end
            end
          end

          context "when there should be a webhook triggered for each consumer version that had a pact verified" do
            # let(:triggered_webhooks) { [instance_double(TriggeredWebhook, event_context: { some: 'context'}, webhook: instance_double(Webhook, uuid: "webhook-uuid"))]}

            before do
              allow(pact_service).to receive(:find_pact).and_return(pact_for_consumer_version_1, pact_for_consumer_version_2)
              # allow(pact_service).to receive(:find_pact).with(hash_including(consumer_version_number: "2")).and_return(pact_for_consumer_version_2)
            end
            let(:event_name) { PactBroker::Webhooks::WebhookEvent::VERIFICATION_SUCCEEDED }
            let(:pact) { instance_double(PactBroker::Domain::Pact, provider_name: provider.name, consumer_name: consumer.name, consumer: consumer, provider: provider, consumer_version: consumer_version)}
            let(:consumer_version) { PactBroker::Domain::Version.new(number: "1.2.3") }
            let(:consumer) { PactBroker::Domain::Pacticipant.new(name: "Consumer") }
            let(:provider) { PactBroker::Domain::Pacticipant.new(name: "Provider") }

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
            let(:expected_event_context_1) { { event_name: event_name, consumer_version_number: "1", consumer_version_tags: ["prod", "main"], other: "foo" } }
            let(:expected_event_context_2) { { event_name: event_name, consumer_version_number: "2", consumer_version_tags: ["feat/2"], other: "foo" } }
            let(:pact_for_consumer_version_1) { double("pact_for_consumer_version_1") }
            let(:pact_for_consumer_version_2) { double("pact_for_consumer_version_2") }

            it "finds the pact publication for each consumer version number" do
              expect(pact_service).to receive(:find_pact).with(hash_including(consumer_version_number: "1")).and_return(pact_for_consumer_version_1)
              expect(pact_service).to receive(:find_pact).with(hash_including(consumer_version_number: "2")).and_return(pact_for_consumer_version_2)
              subject
            end

            context "when there are consumer_version_selectors in the event_context" do
              it "creates a triggered webhook for each consumer version (ie. commit)" do
                expect(webhook_repository).to receive(:create_triggered_webhook).with(anything, webhook, pact_for_consumer_version_1, verification, TriggerService::RESOURCE_CREATION, event_name, expected_event_context_1)
                expect(webhook_repository).to receive(:create_triggered_webhook).with(anything, webhook, pact_for_consumer_version_2, verification, TriggerService::RESOURCE_CREATION, event_name, expected_event_context_2)
                subject
              end
            end

            context "when there are no consumer_version_selectors" do
              let(:event_context) { { some: "data" } }

              it "passes through the event context and only makes one triggered webhook" do
                expect(webhook_repository).to receive(:create_triggered_webhook).with(anything, webhook, pact, verification, TriggerService::RESOURCE_CREATION, PactBroker::Webhooks::WebhookEvent::VERIFICATION_SUCCEEDED, event_context.merge(event_name: event_name))
                subject
              end
            end
          end
        end
      end

      describe ".schedule_webhooks" do
        let(:options) do
          { database_connector: double("database_connector"),
            webhook_execution_configuration: webhook_execution_configuration,
            logging_options: {}
          }
        end
        let(:triggered_webhook) { instance_double(PactBroker::Webhooks::TriggeredWebhook, webhook: webhook, event_context: {}) }
        let(:triggered_webhooks) { [triggered_webhook] }
        let(:webhook_execution_configuration) { double("webhook_execution_configuration", webhook_context: webhook_context) }
        let(:webhook_context) { { base_url: "http://example.org" } }
        let(:webhook) do
          instance_double(PactBroker::Domain::Webhook, description: "description", uuid: "1244")
        end

        subject { TriggerService.schedule_webhooks(triggered_webhooks, options) }

        context "when there is a scheduling error", job: true do
          before do
            allow(TriggerService).to receive(:logger).and_return(logger)
          end

          let(:logger) { double("logger").as_null_object }

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
            consumer_name: "consumer",
            provider_name: "provider",
            execute: result
          )
        end
        let(:pact) { instance_double(PactBroker::Domain::Pact) }
        let(:verification) { instance_double(PactBroker::Domain::Verification) }
        let(:trigger_on_verification) { false }
        let(:result) { double("result") }
        let(:execution_configuration) do
          instance_double(PactBroker::Webhooks::ExecutionConfiguration, to_hash: execution_configuration_hash)
        end
        let(:execution_configuration_hash) { { the: "options" } }
        let(:event_context) { { some: "data" } }

        before do
          allow(PactBroker::Pacts::Service).to receive(:search_for_latest_pact).and_return(pact)
          allow(PactBroker::Verifications::Service).to receive(:search_for_latest).and_return(verification)
          allow(PactBroker.configuration).to receive(:show_webhook_response?).and_return("foo")
          allow(execution_configuration).to receive(:with_failure_log_message).and_return(execution_configuration)
        end

        subject { TriggerService.test_execution(webhook, event_context, execution_configuration) }

        it "searches for the latest matching pact" do
          expect(PactBroker::Pacts::Service).to receive(:search_for_latest_pact).with(consumer_name: "consumer", provider_name: "provider")
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
            expect(PactBroker::Verifications::Service).to receive(:search_for_latest).with("consumer", "provider")
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
            .with_webhook_context(base_url: "http://example.org")
            .with_retry_schedule([10, 60, 120, 300, 600, 1200])
            .with_http_success_codes([200])
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
            .create_webhook(method: "GET", url: "http://example.org", events: events)
            .and_return(:pact)
        end

        let(:triggered_webhooks) { PactBroker::Webhooks::TriggerService.create_triggered_webhooks_for_event(pact, td.verification, PactBroker::Webhooks::WebhookEvent::CONTRACT_CONTENT_CHANGED, event_context) }

        subject {  PactBroker::Webhooks::TriggerService.schedule_webhooks(triggered_webhooks, options) }

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
