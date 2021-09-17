require "pact_broker/webhooks/webhook"

module PactBroker
  module Webhooks
    describe Webhook do
      before do
        td.create_consumer("Foo")
          .create_provider("Bar")
          .create_label("label1")
          .create_consumer_version
          .create_pact
          .create_global_webhook
          .create_consumer_webhook
          .create_provider_webhook
          .create_provider("Wiffle")
          .create_provider_webhook
          .create_webhook(provider: nil, consumer: nil, provider_label: "label1")
          .create_webhook(provider: nil, consumer: nil, consumer_label: "label2", provider_label: "label1")
      end

      let(:consumer) { PactBroker::Domain::Pacticipant.find(name: "Foo") }
      let(:provider) { PactBroker::Domain::Pacticipant.find(name: "Bar") }
      let(:pact) { PactBroker::Pacts::PactPublication.find(id: td.pact.id) }

      describe "#is_for?" do
        let(:matching_webhook_uuids) { Webhooks::Webhook.find_by_consumer_and_or_provider(consumer, provider).collect(&:uuid) }
        let(:matching_webhooks) { Webhooks::Webhook.where(uuid: matching_webhook_uuids) }
        let(:non_matching_webhooks) { Webhooks::Webhook.exclude(uuid: matching_webhook_uuids) }

        it "matches the implementation of Webhook::Repository#find_by_consumer_and_or_provider" do
          expect(matching_webhooks).not_to be_empty
          expect(non_matching_webhooks).not_to be_empty
          expect(matching_webhooks.reject{|w| w.is_for?(pact)}).to be_empty
          expect(non_matching_webhooks.reject{|w| !w.is_for?(pact)}).to be_empty
        end
      end
    end
  end
end
