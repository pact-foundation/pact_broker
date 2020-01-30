require 'pact_broker/api/decorators/triggered_webhook_decorator'

module PactBroker
  module Api
    module Decorators
      describe TriggeredWebhookDecorator do
        let(:triggered_webhook) do
          double('PactBroker::Webhooks::TriggeredWebhook',
            trigger_type: PactBroker::Webhooks::TriggeredWebhook::TRIGGER_TYPE_RESOURCE_CREATION,
            status: status,
            failure?: failure,
            retrying?: retrying,
            trigger_uuid: '1234',
            webhook_uuid: '4321',
            request_description: "GET http://foo",
            pact_publication: pact,
            number_of_attempts_made: 1,
            number_of_attempts_remaining: 2,
            created_at: DateTime.new(2017),
            updated_at: DateTime.new(2017)
          )
        end

        let(:pact) do
          double('pact',
            provider: double(name: 'provider'),
            consumer: double(name: 'consumer'),
            consumer_version_number: '1',
            name: 'foo '
          )
        end

        let(:failure) { false }
        let(:retrying) { false }
        let(:status) { PactBroker::Webhooks::TriggeredWebhook::STATUS_SUCCESS }
        let(:logs_url) { "http://example.org/webhooks/4321/trigger/1234/logs" }
        let(:user_options) { { base_url: "http://example.org" } }

        let(:json) do
          TriggeredWebhookDecorator.new(triggered_webhook).to_json(user_options: user_options)
        end

        subject { JSON.parse(json, symbolize_names: true) }

        it "includes a link to the logs" do
          expect(subject[:_links][:'pb:logs'][:href]).to eq logs_url
        end

        it "includes a link to the webhook" do
          expect(subject[:_links][:'pb:webhook'][:href]).to eq "http://example.org/webhooks/4321"
        end

        it "includes the triggered webhooks properties" do
          expect(subject).to include(
            status: 'success',
            triggerType: 'resource_creation',
            attemptsMade: 1,
            attemptsRemaining: 2
          )
        end
      end
    end
  end
end
