require 'pact_broker/webhooks/webhook'

module PactBroker
  module Webhooks
    describe Webhook do
      before do
        td.create_consumer("Foo")
          .create_provider("Bar")
          .create_consumer_version
          .create_pact
          .create_global_webhook
          .create_consumer_webhook
          .create_provider_webhook
          .create_provider("Wiffle")
          .create_provider_webhook
      end

      let(:consumer) { PactBroker::Domain::Pacticipant.find(name: "Foo") }
      let(:provider) { PactBroker::Domain::Pacticipant.find(name: "Bar") }
      let(:pact) { double(consumer_id: consumer.id, provider_id: provider.id).as_null_object }

      describe "#is_for?" do
        let(:matching_webhook_uuids) { Webhooks::Webhook.find_by_consumer_and_or_provider(consumer, provider).collect(&:uuid) }
        let(:matching_webhooks) { Webhooks::Webhook.where(uuid: matching_webhook_uuids) }
        let(:non_matching_webhooks) { Webhooks::Webhook.exclude(uuid: matching_webhook_uuids) }

        it "matches the implementation of Webhook::Repository#find_by_consumer_and_or_provider" do
          expect(matching_webhooks.count).to be > 0
          expect(non_matching_webhooks.count).to be > 0
          expect(matching_webhooks.all?{|w| w.is_for?(pact)}).to be true
          expect(non_matching_webhooks.all?{|w| !w.is_for?(pact)}).to be true
        end
      end
    end
  end
end
