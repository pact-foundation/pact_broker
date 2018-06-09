require 'spec_helper'
require 'pact_broker/webhooks/repository'

module PactBroker
  module Webhooks
    describe Repository do

      let(:td) { TestDataBuilder.new }
      let(:url) { 'http://example.org' }
      let(:body) { {'some' => 'json' } }
      let(:headers) { {'Content-Type' => 'application/json', 'Accept' => 'application/json'} }
      let(:request) do
        Domain::WebhookRequest.new(
          method: 'post',
          url: url,
          headers: headers,
          username: 'username',
          password: 'password',
          body: body)
      end
      let(:event) do
        PactBroker::Webhooks::WebhookEvent.new(name: 'something_happened')
      end
      let(:events) { [event]}
      let(:webhook) { Domain::Webhook.new(request: request, events: events)}
      let(:test_data_builder) { TestDataBuilder.new }
      let(:consumer) { test_data_builder.create_pacticipant 'Consumer'; test_data_builder.pacticipant}
      let(:provider) { test_data_builder.create_pacticipant 'Provider'; test_data_builder.pacticipant}
      let(:uuid) { 'the-uuid' }
      let(:created_webhook_record) { ::DB::PACT_BROKER_DB[:webhooks].order(:id).last }
      let(:created_headers) { ::DB::PACT_BROKER_DB[:webhook_headers].where(webhook_id: created_webhook_record[:id]).order(:name).all }
      let(:created_events) { ::DB::PACT_BROKER_DB[:webhook_events].where(webhook_id: created_webhook_record[:id]).order(:name).all }
      let(:expected_webhook_record) do
        {
          uuid: "the-uuid",
          method: "post",
          url: "http://example.org",
          username: 'username',
          password:  "cGFzc3dvcmQ=",
          body: body.to_json,
          consumer_id:  consumer.id,
          provider_id:  provider.id
        }
      end

      describe "#create" do

        subject { Repository.new.create uuid, webhook, consumer, provider }

        it "saves webhook" do
          subject
          expect(created_webhook_record).to include expected_webhook_record
        end

        it "saves the headers" do
          subject
          expect(created_headers.size).to eq 2
          expect(created_headers.first[:name]).to eq "Accept"
          expect(created_headers.first[:value]).to eq "application/json"
          expect(created_headers.last[:name]).to eq "Content-Type"
          expect(created_headers.last[:value]).to eq "application/json"
        end

        it "saves the webhook events" do
          expect(subject.events.first[:name]).to eq "something_happened"
        end

      end

      describe "delete_by_uuid" do

        before do
          Repository.new.create uuid, webhook, consumer, provider
          Repository.new.create 'another-uuid', webhook, consumer, provider
        end

        subject { Repository.new.delete_by_uuid uuid }

        it "deletes the webhook headers" do
          expect { subject }.to change {
            ::DB::PACT_BROKER_DB[:webhook_headers].count
            }.by(-2)
        end

        it "deletes the webhook" do
          expect { subject }.to change {
            ::DB::PACT_BROKER_DB[:webhooks].where(uuid: uuid).count
            }.by(-1)
        end
      end

      describe "delete_by_pacticipant" do

        before do
          allow(SecureRandom).to receive(:urlsafe_base64).and_return(uuid, 'another-uuid')
          Repository.new.create uuid, webhook, consumer, provider
        end

        context "when the pacticipant is the consumer" do

          subject { Repository.new.delete_by_pacticipant consumer }

          it "deletes the webhook" do
            expect { subject }.to change {
              ::DB::PACT_BROKER_DB[:webhooks].where(uuid: uuid).count
              }.by(-1)
          end
        end

        context "when the pacticipant is the provider" do

          subject { Repository.new.delete_by_pacticipant provider }

          it "deletes the webhook" do
            expect { subject }.to change {
              ::DB::PACT_BROKER_DB[:webhooks].where(uuid: uuid).count
              }.by(-1)
          end
        end

      end

      describe "find_by_uuid" do


        subject { Repository.new.find_by_uuid uuid }

        context "when a webhook is found" do
          before do
            Repository.new.create uuid, webhook, consumer, provider
          end

          it "returns a webhook with the consumer set" do
            expect(subject.consumer.id).to eq consumer.id
            expect(subject.consumer.name).to eq consumer.name
          end

          it "returns a webhook with the provider set" do
            expect(subject.provider.id).to eq provider.id
            expect(subject.provider.name).to eq provider.name
          end

          it "returns a webhook with the uuid set" do
            expect(subject.uuid).to eq uuid
          end

          it "returns a webhook with the body set" do
            expect(subject.request.body).to eq body
          end

          it "returns a webhook with the headers set" do
            expect(subject.request.headers).to eq headers
          end


          it "returns a webhook with the username set" do
            expect(subject.request.username).to eq 'username'
          end

          it "returns a webhook with the password set" do
            expect(subject.request.password).to eq 'password'
          end

          it "returns a webhook with the url set" do
            expect(subject.request.url).to eq url
          end

          it "returns a webhook with a created_at date" do
            expect(subject.created_at).to be_datey
          end

          it "returns a webhook with a updated_at date" do
            expect(subject.updated_at).to be_datey
          end

          context "when the body is a XML string" do
            let(:body) { "<xml>Why would you do this?</xml>" }

            it "returns the body as the XML String, not an JSON Object" do
              expect(subject.request.body).to eq body
            end
          end

          context "when the optional attributes are nil" do
            let(:body) { nil }
            let(:headers) { nil }

            it "does not blow up" do
              expect(subject.request.body).to eq body
              expect(subject.request.headers).to eq({})
            end
          end
        end

        context "when a webhook is not found" do
          it "returns nil" do
            expect(subject).to be nil
          end
        end

      end

      describe "update_by_uuid" do
        let(:uuid) { '1234' }
        let(:td) { TestDataBuilder.new }
        let(:old_webhook_params) do
          {
            events: [{ name: 'something' }],
            uuid: uuid,
            method: 'POST',
            url: 'http://example.org',
            body: '{"foo":1}',
            headers: {'Content-Type' => 'application/json'},
            username: 'username',
            password: 'password'
          }
        end
        let(:new_webhook_params) do
          {
            method: 'GET',
            url: 'http://example.com',
            body: 'foo',
            headers: {'Content-Type' => 'text/plain'}
          }
        end
        let(:new_event) do
          PactBroker::Webhooks::WebhookEvent.new(name: 'something_else')
        end
        before do
          td.create_consumer
            .create_provider
            .create_webhook(old_webhook_params)
        end
        let(:new_webhook) do
          PactBroker::Domain::Webhook.new(events: [new_event], request: PactBroker::Domain::WebhookRequest.new(new_webhook_params))
        end

        subject { Repository.new.update_by_uuid uuid, new_webhook }

        it "updates the webhook" do
          updated_webhook = subject
          expect(updated_webhook.uuid).to eq uuid
          expect(updated_webhook.request.method).to eq 'GET'
          expect(updated_webhook.request.url).to eq 'http://example.com'
          expect(updated_webhook.request.body).to eq 'foo'
          expect(updated_webhook.request.headers).to eq 'Content-Type' => 'text/plain'
          expect(updated_webhook.request.username).to eq nil
          expect(updated_webhook.request.password).to eq nil
          expect(updated_webhook.events.first.name).to eq 'something_else'
        end
      end

      describe "find_all" do
        before do
          Repository.new.create uuid, webhook, consumer, provider
          Repository.new.create 'some-other-uuid', webhook, consumer, provider
        end

        subject { Repository.new.find_all }

        it "returns a list of webhooks" do
          expect(subject.size).to be 2
          expect(subject.first).to be_instance_of Domain::Webhook
        end
      end

      describe "find_by_consumer_and_provider" do
        let(:test_data_builder) { TestDataBuilder.new }
        subject { Repository.new.find_by_consumer_and_provider test_data_builder.consumer, test_data_builder.provider}

        context "when a webhook exists with a matching consumer and provider" do

          before do
            allow(SecureRandom).to receive(:urlsafe_base64).and_call_original
            test_data_builder
              .create_consumer("Consumer")
              .create_provider("Another Provider")
              .create_webhook
              .create_provider("Provider")
              .create_webhook
          end


          it "returns an array of webhooks" do
            expect(subject).to be_instance_of Array
            expect(subject.first.uuid).to eq test_data_builder.webhook.uuid
          end
        end

        context "when a webhook does not exist with a matching consumer and provider" do

          before do
            test_data_builder
              .create_consumer("Consumer")
              .create_provider("Provider")
              .create_webhook
              .create_provider("Another Provider")
          end

          it "returns an empty array" do
            expect(subject).to eq []
          end
        end
      end

      describe "find_by_consumer_and_provider_and_event_name" do
        let(:test_data_builder) { TestDataBuilder.new }
        subject { Repository.new.find_by_consumer_and_provider_and_event_name test_data_builder.consumer, test_data_builder.provider, 'something_happened' }

        context "when a webhook exists with a matching consumer and provider and event name" do

          before do
            test_data_builder
              .create_consumer("Consumer")
              .create_provider("Another Provider")
              .create_webhook
              .create_provider("Provider")
              .create_webhook(uuid: '1', events: [{ name: 'something_happened' }])
              .create_webhook(uuid: '2', events: [{ name: 'something_happened' }])
              .create_webhook(uuid: '3', events: [{ name: 'something_else_happened' }])
          end

          it "returns an array of webhooks" do
            expect(subject.collect(&:uuid).sort).to eq ['1', '2']
          end
        end
      end

      describe "create_triggered_webhook" do
        before do
          td.create_consumer
            .create_provider
            .create_webhook
            .create_consumer_version
            .create_pact
            .create_verification
        end

        subject { Repository.new.create_triggered_webhook '1234', td.webhook, td.pact, td.verification, 'publication' }

        it "creates a TriggeredWebhook" do
          expect(subject.webhook_uuid ).to eq td.webhook.uuid
          expect(subject.consumer).to eq td.consumer
          expect(subject.provider).to eq td.provider
          expect(subject.verification).to eq td.verification
          expect(subject.trigger_uuid).to eq '1234'
          expect(subject.trigger_type).to eq 'publication'
        end

        it "sets the webhook" do
          expect(subject.webhook.uuid).to eq td.webhook.uuid
        end

        it "sets the webhook_uuid" do
          expect(subject.webhook_uuid).to eq td.webhook.uuid
        end

        it "sets the consumer" do
          expect(subject.consumer).to eq td.consumer
        end

        it "sets the provider" do
          expect(subject.provider).to eq td.provider
        end

        it "sets the PactPublication" do
          expect(subject.pact_publication.id).to eq td.pact.id
        end

        context "without a verification" do
          subject { Repository.new.create_triggered_webhook '1234', td.webhook, td.pact, nil, 'publication' }

          it "does not set the verification" do
            expect(subject.verification).to be nil
          end
        end
      end

      describe "create_execution" do
        before do
          td.create_consumer
            .create_provider
            .create_consumer_version
            .create_pact
            .create_webhook
            .create_triggered_webhook
        end

        let(:webhook_domain) { Repository.new.find_by_uuid td.webhook.uuid }
        let(:webhook_execution_result) { instance_double("PactBroker::Domain::WebhookExecutionResult", success?: true, logs: "logs") }

        subject { Repository.new.create_execution td.triggered_webhook, webhook_execution_result }

        it "saves a new webhook execution " do
          expect { subject }.to change { Execution.count }.by(1)
        end

        it "sets the success" do
          expect(subject.success).to be true
        end

        it "sets the logs" do
          expect(subject.logs).to eq "logs"
        end
      end

      describe "delete_triggered_webhooks_by_webhook_uuid" do
        let(:td) { TestDataBuilder.new }

        before do
          td.create_consumer
            .create_provider
            .create_consumer_version
            .create_pact
            .create_webhook
            .create_triggered_webhook
            .create_deprecated_webhook_execution
            .create_webhook_execution
            .create_webhook
            .create_triggered_webhook
            .create_deprecated_webhook_execution
            .create_webhook_execution
        end

        let(:webhook_id) { Webhook.find(uuid: td.webhook.uuid).id }
        subject { Repository.new.delete_triggered_webhooks_by_webhook_uuid td.webhook.uuid }

        it "deletes the related triggered webhooks" do
          expect { subject }.to change {
              TriggeredWebhook.where(id: td.triggered_webhook.id).count
            }.from(1).to(0)
        end

        it "does not delete the unrelated triggered webhooks" do
          expect { subject }.to_not change {
              TriggeredWebhook.exclude(id: td.triggered_webhook.id).count
            }
        end

        it "deletes the related deprecated webhook executions" do
          expect { subject }.to change {
              DeprecatedExecution.count
            }.by(-2)
        end

        it "deletes the related webhook executions" do
          expect { subject }.to change {
              Execution.count
            }.by(-2)
        end
      end

      describe "delete_executions_by_pacticipant" do
        before do
          td.create_consumer
            .create_provider
            .create_webhook
            .create_consumer_version
            .create_pact
            .create_triggered_webhook
            .create_webhook_execution
          # Replicate the old way of doing it
        end

        context "with triggered webhooks" do
          it "deletes the execution by consumer" do
            expect { Repository.new.delete_executions_by_pacticipant td.consumer }
              .to change { Execution.count }.by(-1)
          end

          it "deletes the execution by provider" do
            expect { Repository.new.delete_executions_by_pacticipant td.provider }
              .to change { Execution.count }.by(-1)
          end

          it "does not delete executions for non related pacticipants" do
            another_consumer = td.create_consumer.and_return(:consumer)
            expect { Repository.new.delete_executions_by_pacticipant another_consumer }
              .to change { Execution.count }.by(0)
          end
        end

        context "with deprecated executions (before the triggered webhook table was introduced)" do
          before do
            Sequel::Model.db[:webhook_executions].update(triggered_webhook_id: nil, consumer_id: td.consumer.id, provider_id: td.provider.id)
            TriggeredWebhook.select_all.delete
          end

          it "deletes the execution by consumer" do
            expect { Repository.new.delete_executions_by_pacticipant td.consumer }
              .to change { Execution.count }.by(-1)
          end

          it "deletes the execution by provider" do
            expect { Repository.new.delete_executions_by_pacticipant td.provider }
              .to change { Execution.count }.by(-1)
          end

          it "does not delete executions for non related pacticipants" do
            another_consumer = td.create_consumer.and_return(:consumer)
            expect { Repository.new.delete_executions_by_pacticipant another_consumer }
              .to change { Execution.count }.by(0)
          end
        end
      end

      describe "find_latest_triggered_webhooks" do
        before do
          td
            .create_pact_with_hierarchy("Foo", "1.0.0", "Bar")
            .create_webhook
            .create_triggered_webhook
            .create_webhook_execution
            .create_pact_with_hierarchy
            .create_webhook(uuid: '123')
            .create_triggered_webhook(trigger_uuid: '256', created_at: DateTime.new(2016))
            .create_webhook_execution
            .create_triggered_webhook(trigger_uuid: '332', created_at: DateTime.new(2017))
            .create_webhook_execution
            .create_webhook(uuid: '987')
            .create_triggered_webhook(trigger_uuid: '876', created_at: DateTime.new(2017))
            .create_webhook_execution
            .create_triggered_webhook(trigger_uuid: '638', created_at: DateTime.new(2018))
            .create_webhook_execution
        end

        subject { Repository.new.find_latest_triggered_webhooks(td.consumer, td.provider) }

        it "finds the latest triggered webhooks" do
          expect(subject.collect(&:trigger_uuid).sort).to eq ['332', '638']
        end

        context "when there are two 'latest' triggered webhooks at the same time" do
          before do
            td.create_triggered_webhook(trigger_uuid: '888', created_at: DateTime.new(2018))
              .create_webhook_execution
          end

          it "returns the one with the bigger ID" do
            expect(subject.collect(&:trigger_uuid).sort).to eq ['332', '888']
          end
        end

        context "when there are no triggered webhooks for the given consumer and provider" do
          before do
            td.create_consumer
              .create_provider
          end

          it "returns an empty list" do
            expect(subject).to be_empty
          end
        end
      end

      describe "fail_retrying_triggered_webhooks" do
        before do
          td.create_pact_with_hierarchy
            .create_webhook
            .create_triggered_webhook(status: TriggeredWebhook::STATUS_RETRYING)
            .create_triggered_webhook(status: TriggeredWebhook::STATUS_SUCCESS)
            .create_triggered_webhook(status: TriggeredWebhook::STATUS_NOT_RUN)
            .create_triggered_webhook(status: TriggeredWebhook::STATUS_FAILURE)
        end

        it "sets the triggered_webhooks with retrying status to failed" do
          Repository.new.fail_retrying_triggered_webhooks
          expect(TriggeredWebhook.failed.count).to eq 2
          expect(TriggeredWebhook.retrying.count).to eq 0
          expect(TriggeredWebhook.successful.count).to eq 1
          expect(TriggeredWebhook.not_run.count).to eq 1
        end
      end

      describe "delete_triggered_webhooks_by_pact_publication_id" do
        before do
          td.create_pact_with_hierarchy
            .create_webhook
            .create_triggered_webhook
            .create_webhook_execution
            .create_pact_with_hierarchy("A Consumer", "1.2.3", "A Provider")
            .create_webhook
            .create_triggered_webhook
            .create_webhook_execution
            .create_deprecated_webhook_execution
        end

        subject { Repository.new.delete_triggered_webhooks_by_pact_publication_ids [td.pact.id] }

        it "deletes the triggered webhook" do
          expect { subject }.to change {
            TriggeredWebhook.count
          }.by(-1)
        end

        it "deletes the webhook_execution" do
          expect { subject }.to change {
            Execution.exclude(triggered_webhook_id: nil).count
          }.by(-1)
        end

        it "deletes the deprecated webhook_execution" do
          expect { subject }.to change {
            Execution.exclude(consumer_id: nil).count
          }.by(-1)
        end
      end
    end
  end
end
