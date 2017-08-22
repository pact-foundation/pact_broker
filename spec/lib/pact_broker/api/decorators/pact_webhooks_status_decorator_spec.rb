require 'pact_broker/api/decorators/pact_webhooks_status_decorator'

module PactBroker
  module Api
    module Decorators
      describe PactWebhooksStatusDecorator do

        let(:user_options) do
          {consumer: 'Foo', provider: 'Bar', resource_url: 'http://example.org/foo', base_url: 'http://example.org'}
        end

        let(:triggered_webhook) do
          double('PactBroker::Webhooks::TriggeredWebhook',
            trigger_type: PactBroker::Webhooks::TriggeredWebhook::TRIGGER_TYPE_PUBLICATION,
            status: 'foo',
            trigger_uuid: '1234',
            webhook_uuid: '4321',
            request_description: "GET http://foo",
            created_at: DateTime.new(2017),
            updated_at: DateTime.new(2017)
          )
        end

        let(:pact_webhooks_status_summary) do
          instance_double('PactBroker::Webhooks::StatusSummary',
            triggered_webhooks: [triggered_webhook],
            success: true
          )
        end

        let(:json) do
          PactWebhooksStatusDecorator.new(pact_webhooks_status_summary).to_json(user_options: user_options)
        end

        subject { JSON.parse json, symbolize_names: true }

        it "includes the overall success status" do
          expect(subject[:success]).to eq true
        end

        it "includes a list of triggered webhooks" do
          expect(subject[:_embedded][:triggeredWebhooks]).to be_instance_of(Array)
        end

        it "includes a link to the logs" do
          expect(subject[:_embedded][:triggeredWebhooks][0][:_links][:logs][:href]).to eq "http://example.org/webhooks/4321/trigger/1234"
        end

        it "includes the triggered webhooks properties" do
          expect(subject[:_embedded][:triggeredWebhooks].first).to include(status: 'foo', triggerType: 'pact_publication')
        end

        it "includes a link to the consumer" do
          expect(subject[:_links][:'pb:consumer']).to_not be nil
        end

        it "includes a link to the provider" do
          expect(subject[:_links][:'pb:provider']).to_not be nil
        end
      end
    end
  end
end
