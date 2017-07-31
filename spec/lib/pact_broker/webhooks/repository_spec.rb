require 'spec_helper'
require 'pact_broker/webhooks/repository'

module PactBroker
  module Webhooks
    describe Repository do

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
      let(:webhook) { Domain::Webhook.new(request: request)}
      let(:test_data_builder) { TestDataBuilder.new }
      let(:consumer) { test_data_builder.create_pacticipant 'Consumer'; test_data_builder.pacticipant}
      let(:provider) { test_data_builder.create_pacticipant 'Provider'; test_data_builder.pacticipant}
      let(:uuid) { 'the-uuid' }
      let(:created_webhook_record) { ::DB::PACT_BROKER_DB[:webhooks].order(:id).last }
      let(:created_headers) { ::DB::PACT_BROKER_DB[:webhook_headers].where(webhook_id: created_webhook_record[:id]).order(:name).all }
      let(:expected_webhook_record) { {
        :uuid=>"the-uuid",
        :method=>"post",
        :url=>"http://example.org",
        :username => 'username',
        :password => "cGFzc3dvcmQ=",
        :body=>body.to_json,
        :consumer_id=> consumer.id,
        :provider_id=> provider.id } }

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

      describe "create_execution" do
        let(:webhook_domain) { Repository.new.create uuid, webhook, consumer, provider }
        let(:webhook_execution_result) { instance_double("PactBroker::Domain::WebhookExecutionResult", success?: true, logs: "logs") }

        subject { Repository.new.create_execution webhook_domain, webhook_execution_result }

        it "saves a new webhook execution " do
          expect { subject }.to change { Execution.count }.by(1)
        end

        it "sets the webhook" do
          expect(subject.webhook.uuid).to eq webhook_domain.uuid
        end

        it "sets the webhook_uuid" do
          expect(subject.webhook_uuid).to eq webhook_domain.uuid
        end

        it "sets the success" do
          expect(subject.success).to be true
        end

        it "sets the logs" do
          expect(subject.logs).to eq "logs"
        end

        it "sets the consumer" do
          expect(subject.consumer).to eq consumer
        end

        it "sets the provider" do
          expect(subject.provider).to eq provider
        end

        it "sets the PactPublication" do
          expect(subject.pact_publication)
        end
      end

      describe "unlink_executions_by_webhook_uuid" do
        let!(:webhook_domain) { Repository.new.create uuid, webhook, consumer, provider }
        let!(:webhook_execution_result) { instance_double("PactBroker::Domain::WebhookExecutionResult", success?: true, logs: "logs") }
        let!(:webhook_execution) { Repository.new.create_execution webhook_domain, webhook_execution_result }

        subject { Repository.new.unlink_executions_by_webhook_uuid uuid }

        it "sets the webhook id to nil" do
          webhook_id = Webhook.find(uuid: uuid).id
          expect { subject }.to change {
              Execution.find(id: webhook_execution.id).webhook_id
            }.from(webhook_id).to(nil)
        end
      end
    end
  end
end
