require 'spec_helper'
require 'pact_broker/repositories/webhook_repository'

module PactBroker
  module Repositories
    describe WebhookRepository do

      describe "#create" do

        let(:body) { {'some' => 'json' } }
        let(:headers) { {'Content-Type' => 'application/json'} }
        let(:request) { Models::WebhookRequest.new(method: 'post', url: 'http://example.org', headers: headers, body: body)}
        let(:webhook) { Models::Webhook.new(request: request)}
        let(:test_data_builder) { ProviderStateBuilder.new }
        let(:consumer) { test_data_builder.create_pacticipant 'Consumer'; test_data_builder.pacticipant}
        let(:provider) { test_data_builder.create_pacticipant 'Provider'; test_data_builder.pacticipant}
        let(:uuid) { 'the-uuid' }
        let(:created_webhook_record) { ::DB::PACT_BROKER_DB[:webhooks].order(:id).last }
        let(:expected_webhook_record) { {
          :uuid=>"the-uuid",
          :method=>"post",
          :url=>"http://example.org",
          :body=>body.to_json,
          :consumer_id=> consumer.id,
          :provider_id=> provider.id } }

        subject { WebhookRepository.new.create webhook, consumer, provider }

        before do
          allow(SecureRandom).to receive(:urlsafe_base64).and_return(uuid)
        end

        it "generates a UUID" do
          expect(SecureRandom).to receive(:urlsafe_base64)
          subject
        end

        it "saves webhook" do
          subject
          expect(created_webhook_record).to include expected_webhook_record
        end

      end

    end
  end
end