require 'spec_helper'
require 'pact_broker/webhooks/repository'

module PactBroker
  module Webhooks
    describe Repository do
      let(:url) { 'http://example.org' }
      let(:body) { {'some' => 'json' } }
      let(:headers) { {'Content-Type' => 'application/json', 'Accept' => 'application/json'} }
      let(:request) do
        Webhooks::WebhookRequestTemplate.new(
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
      let(:webhook) { Domain::Webhook.new(request: request, events: events) }
      let(:consumer) { td.create_pacticipant('Consumer').and_return(:pacticipant) }
      let(:provider) { td.create_pacticipant('Provider').and_return(:pacticipant) }
      let(:uuid) { 'the-uuid' }
      let(:created_webhook_record) { ::DB::PACT_BROKER_DB[:webhooks].order(:id).last }
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
        subject { Repository.new.create(uuid, webhook, consumer, provider) }

        it "saves webhook" do
          subject
          expect(created_webhook_record).to include expected_webhook_record
        end

        it "saves the webhook headers as JSON" do
          subject
          expect(JSON.parse(created_webhook_record[:headers])).to eq headers
        end

        it "saves the webhook events" do
          expect(subject.events.first[:name]).to eq "something_happened"
        end

        context "when consumer and provider domain objects are set on the object rather than passed in" do
          let(:webhook) { Domain::Webhook.new(request: request, events: events, consumer: consumer, provider: provider) }

          subject { Repository.new.create(uuid, webhook, nil, nil) }

          it "sets the consumer and provider relationships" do
            expect(subject.consumer.id).to eq consumer.id
            expect(subject.provider.id).to eq provider.id
          end
        end
      end

      describe "delete_by_uuid" do
        before do
          Repository.new.create uuid, webhook, consumer, provider
          Repository.new.create 'another-uuid', webhook, consumer, provider
        end

        subject { Repository.new.delete_by_uuid(uuid) }

        it "deletes the webhook" do
          expect { subject }.to change {
            ::DB::PACT_BROKER_DB[:webhooks].where(uuid: uuid).count
            }.by(-1)
        end
      end

      describe "delete_by_pacticipant" do

        before do
          allow(SecureRandom).to receive(:urlsafe_base64).and_return(uuid, 'another-uuid')
          Repository.new.create(uuid, webhook, consumer, provider)
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
        subject { Repository.new.find_by_uuid(uuid) }

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
        before do
          td.create_consumer("Foo")
            .create_provider
            .create_webhook(old_webhook_params)
            .create_consumer("Foo2")
        end

        let(:uuid) { '1234' }
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
        let(:new_request_webhook_params) do
          {
            method: 'GET',
            url: 'http://example.com',
            body: 'foo',
            headers: {'Content-Type' => 'text/plain'}
          }
        end
        let(:new_request) { PactBroker::Domain::WebhookRequest.new(new_request_webhook_params) }
        let(:new_event) do
          PactBroker::Webhooks::WebhookEvent.new(name: 'something_else')
        end
        let(:new_consumer) { PactBroker::Domain::Pacticipant.new(name: "Foo2") }
        let(:new_webhook) do
          PactBroker::Domain::Webhook.new(
            consumer: new_consumer,
            events: [new_event],
            request: new_request
          )
        end

        subject { Repository.new.update_by_uuid(uuid, new_webhook) }

        it "updates the webhook" do
          expect(subject.uuid).to eq uuid
          expect(subject.request.method).to eq 'GET'
          expect(subject.request.url).to eq 'http://example.com'
          expect(subject.request.body).to eq 'foo'
          expect(subject.request.headers).to eq 'Content-Type' => 'text/plain'
          expect(subject.request.username).to eq nil
          expect(subject.request.password).to eq nil
          expect(subject.events.first.name).to eq 'something_else'
          expect(subject.consumer.name).to eq "Foo2"
        end

        context "when the updated params do not contain a consumer or provider" do
          let(:new_webhook) do
            PactBroker::Domain::Webhook.new(
              events: [new_event],
              request: new_request
            )
          end

          it "removes the existing consumer or provider" do
            expect(subject.consumer).to be nil
          end
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
        let(:consumer) { td.consumer }
        let(:provider) { td.provider }

        subject { Repository.new.find_by_consumer_and_provider(consumer, provider) }

        context "when a webhook exists with a matching consumer and provider" do
          before do
            td.create_consumer("Consumer")
              .create_provider("Another Provider")
              .create_webhook
              .create_provider("Provider")
              .create_webhook
          end

          it "returns an array of webhooks" do
            expect(subject).to be_instance_of Array
            expect(subject.first.uuid).to eq td.webhook.uuid
          end
        end

        context "when a webhook does not exist with a matching consumer and provider" do
          before do
            td
              .create_consumer("Consumer")
              .create_provider("Provider")
              .create_webhook
              .create_provider("Another Provider")
          end

          it "returns an empty array" do
            expect(subject).to eq []
          end
        end

        context "when the consumer argument is nil" do
          let(:consumer) { nil }

          before do
            td.create_provider("Provider")
              .create_consumer("Consumer")
              .create_provider_webhook
              .create_webhook
          end

          it "returns all the webhooks where the provider matches and the consumer id is nil" do
            expect(subject.size).to be 1
            expect(subject.first.consumer).to be nil
            expect(subject.first.provider).to_not be nil
          end
        end

        context "when the provider argument is nil" do
          let(:provider) { nil }

          before do
            td.create_consumer("Consumer")
              .create_provider("Provider")
              .create_consumer_webhook
              .create_webhook
          end

          it "returns all the webhooks where the consumer matches and the provider id is nil" do
            expect(subject.size).to be 1
            expect(subject.first.provider).to be nil
            expect(subject.first.consumer).to_not be nil
          end
        end
      end

      describe "find_by_consumer_and_provider_and_event_name" do
        subject { Repository.new.find_by_consumer_and_provider_and_event_name td.consumer, td.provider, 'something_happened' }

        context "when a webhook exists with a matching consumer and provider and event name" do
          before do
            td
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

          context "when the webhook is not enabled" do
            before do
              Webhook.where(uuid: '2').update(enabled: false)
            end

            it "is not returned" do
              expect(subject.collect(&:uuid).sort).to_not include('2  ')
            end
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

        let(:context) { { 'some' => 'info' } }

        subject { Repository.new.create_triggered_webhook '1234', td.webhook, td.pact, td.verification, 'publication', 'some_event', context }

        it "creates a TriggeredWebhook" do
          expect(subject.webhook_uuid ).to eq td.webhook.uuid
          expect(subject.consumer).to eq td.consumer
          expect(subject.provider).to eq td.provider
          expect(subject.verification).to eq td.verification
          expect(subject.trigger_uuid).to eq '1234'
          expect(subject.trigger_type).to eq 'publication'
          expect(subject.event_name).to eq 'some_event'
          expect(subject.context).to eq context
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
          subject { Repository.new.create_triggered_webhook '1234', td.webhook, td.pact, nil, 'publication', 'some_event', {} }

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
        let(:repository) { Repository.new }

        subject { repository.create_execution td.triggered_webhook, webhook_execution_result }

        it "saves a new webhook execution " do
          expect { subject }.to change { Execution.count }.by(1)
        end

        it "sets the success" do
          expect(subject.success).to be true
        end

        it "sets the logs" do
          expect(subject.logs).to eq "logs"
        end

        context "when the triggered webhook has been deleted in the meantime" do
          before do
            TriggeredWebhook.where(id: td.triggered_webhook.id).delete
            allow(repository).to receive(:logger).and_return(logger)
          end

          let(:logger) { double('logger') }

          it "just logs the error" do
            expect(logger).to receive(:info).with(/triggered webhook with id #{td.triggered_webhook.id}/)
            subject
          end
        end
      end

      describe "delete_triggered_webhooks_by_webhook_uuid" do
        before do
          td.create_consumer
            .create_provider
            .create_consumer_version
            .create_pact
            .create_webhook
            .create_triggered_webhook
            .create_webhook_execution
            .create_webhook
            .create_triggered_webhook
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

        it "deletes the related webhook executions" do
          expect { subject }.to change {
              Execution.count
            }.by(-1)
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

        context "when a webhook has been triggered by different events" do
          before do
            td.create_pact_with_hierarchy("Foo2", "1.0.0", "Bar2")
              .create_webhook
              .create_triggered_webhook(trigger_uuid: '333', event_name: 'foo')
              .create_triggered_webhook(trigger_uuid: '555', event_name: 'foo')
              .create_webhook_execution
              .create_triggered_webhook(trigger_uuid: '444', event_name: 'bar')
              .create_triggered_webhook(trigger_uuid: '777', event_name: 'bar')
              .create_webhook_execution
              .create_triggered_webhook(trigger_uuid: '111', event_name: nil)
              .create_triggered_webhook(trigger_uuid: '888', event_name: nil)
              .create_webhook_execution
          end

          it "returns one for each event" do
            expect(subject.collect(&:trigger_uuid).sort).to eq ['555', '777', '888']
          end
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

      describe "find_latest_triggered_webhooks_for_pact" do
        before do
          td
            .create_pact_with_hierarchy("Foo", "1.0.0", "Bar")
            .create_webhook
            .create_triggered_webhook
            .create_webhook_execution
            .create_pact_with_hierarchy
            .create_webhook
            .create_triggered_webhook(trigger_uuid: '256', created_at: DateTime.new(2016))
            .create_webhook_execution
            .create_triggered_webhook(trigger_uuid: '332', created_at: DateTime.new(2017))
            .create_webhook_execution
            .create_provider_webhook(uuid: '987')
            .create_triggered_webhook(trigger_uuid: '876', created_at: DateTime.new(2017))
            .create_webhook_execution
            .create_triggered_webhook(trigger_uuid: '638', created_at: DateTime.new(2018))
            .create_webhook_execution
            .create_consumer_webhook
            .create_triggered_webhook(trigger_uuid: '555', created_at: DateTime.new(2017))
            .create_webhook_execution
            .create_triggered_webhook(trigger_uuid: '777', created_at: DateTime.new(2018))
            .create_webhook_execution
        end

        subject { Repository.new.find_latest_triggered_webhooks_for_pact(td.pact) }

        it "finds the latest triggered webhooks" do
          expect(subject.collect(&:trigger_uuid).sort).to eq ['332', '638', '777']
        end
      end

      describe "find_triggered_webhooks_for_pact" do
        before do
          td
            .create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_webhook
            .create_triggered_webhook(trigger_uuid: "1")
            .create_webhook_execution
            .create_consumer_version("2")
            .create_pact
            .create_triggered_webhook(trigger_uuid: "2")
            .create_webhook_execution
        end

        subject { Repository.new.find_triggered_webhooks_for_pact(td.pact) }

        it "finds the triggered webhooks" do
          expect(subject.collect(&:trigger_uuid).sort).to eq ["2"]
        end
      end

      describe "find_triggered_webhooks_for_verification" do
        before do
          td
            .create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_verification_webhook
            .create_verification(provider_version: "1")
            .create_triggered_webhook(trigger_uuid: "1")
            .create_verification(provider_version: "2", number: 2)
            .create_triggered_webhook(trigger_uuid: "2")
        end

        subject { Repository.new.find_triggered_webhooks_for_verification(td.verification) }

        it "finds the triggered webhooks" do
          expect(subject.collect(&:trigger_uuid).sort).to eq ["2"]
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
      end

      describe "delete_triggered_webhooks_by_version_id" do
        subject { Repository.new.delete_triggered_webhooks_by_version_id(version.id) }

        context "when deleting a triggered webhook by consumer version" do
          let!(:version) do
            td
              .create_pact_with_hierarchy
              .create_webhook
              .create_triggered_webhook
              .create_webhook_execution
              .and_return(:consumer_version)
          end

          it "deletes the webhooks belonging to the consumer version" do
            expect { subject }.to change{ TriggeredWebhook.count }.by (-1)
          end
        end

        context "when deleting a triggered webhook by provider version" do
          let!(:version) do
            td
              .create_pact_with_hierarchy
              .create_verification(provider_version: "1")
              .create_provider_webhook(event_names: ['provider_verification_published'])
              .create_triggered_webhook
              .create_webhook_execution
              .and_return(:provider_version)
          end

          it "deletes the webhooks belonging to the consumer version" do
            expect { subject }.to change{ TriggeredWebhook.count }.by (-1)
          end
        end
      end
    end
  end
end
