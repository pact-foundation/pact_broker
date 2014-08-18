require 'spec_helper'
require 'pact_broker/repositories/webhook_repository'

module PactBroker
  module Repositories
    describe WebhookRepository do

      let(:url) { 'http://example.org' }
      let(:body) { {'some' => 'json' } }
      let(:headers) { {'Content-Type' => 'application/json', 'Accept' => 'application/json'} }
      let(:request) do
        Models::WebhookRequest.new(
          method: 'post',
          url: url,
          headers: headers,
          username: 'username',
          password: 'password',
          body: body)
      end
      let(:webhook) { Models::Webhook.new(request: request)}
      let(:test_data_builder) { ProviderStateBuilder.new }
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
        :password => 'password',
        :body=>body.to_json,
        :consumer_id=> consumer.id,
        :provider_id=> provider.id } }

      before do
        allow(SecureRandom).to receive(:urlsafe_base64).and_return(uuid)
      end

      describe "#create" do

        subject { WebhookRepository.new.create webhook, consumer, provider }


        it "generates a UUID" do
          expect(SecureRandom).to receive(:urlsafe_base64)
          subject
        end

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
          allow(SecureRandom).to receive(:urlsafe_base64).and_return(uuid, 'another-uuid')
          WebhookRepository.new.create webhook, consumer, provider
          WebhookRepository.new.create webhook, consumer, provider
        end

        subject { WebhookRepository.new.delete_by_uuid uuid }

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
          WebhookRepository.new.create webhook, consumer, provider
        end

        context "when the pacticipant is the consumer" do

          subject { WebhookRepository.new.delete_by_pacticipant consumer }

          it "deletes the webhook" do
            expect { subject }.to change {
              ::DB::PACT_BROKER_DB[:webhooks].where(uuid: uuid).count
              }.by(-1)
          end
        end

        context "when the pacticipant is the provider" do

          subject { WebhookRepository.new.delete_by_pacticipant provider }

          it "deletes the webhook" do
            expect { subject }.to change {
              ::DB::PACT_BROKER_DB[:webhooks].where(uuid: uuid).count
              }.by(-1)
          end
        end

      end



      describe "find_by_uuid" do


        subject { WebhookRepository.new.find_by_uuid uuid }

        context "when a webhook is found" do
          before do
            WebhookRepository.new.create webhook, consumer, provider
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

          it "returns a webhook with the url set" do
            expect(subject.request.url).to eq url
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
          allow(SecureRandom).to receive(:urlsafe_base64).and_return(uuid, 'some-other-uuid')
          WebhookRepository.new.create webhook, consumer, provider
          WebhookRepository.new.create webhook, consumer, provider
        end

        subject { WebhookRepository.new.find_all }

        it "returns a list of webhooks" do
          expect(subject.size).to be 2
          expect(subject.first).to be_instance_of Models::Webhook
        end
      end

      describe "find_by_consumer_and_provider" do
        let(:test_data_builder) { ProviderStateBuilder.new }
        subject { WebhookRepository.new.find_by_consumer_and_provider test_data_builder.consumer, test_data_builder.provider}

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

    end
  end
end