require "pact_broker/api/decorators/triggered_webhooks_decorator"
require "pact_broker/webhooks/triggered_webhook"

module PactBroker
  module Api
    module Decorators
      describe TriggeredWebhooksDecorator do
        let(:triggered_webhook) do
          instance_double(PactBroker::Webhooks::TriggeredWebhook).as_null_object
        end
        let(:decorator) { TriggeredWebhooksDecorator.new([triggered_webhook]) }
        let(:user_options) { { resource_title: "Title", resource_url: "http://url" } }
        let(:json) { decorator.to_json(user_options: user_options) }

        subject { JSON.parse(json) }

        it "includes a self relation" do
          expect(subject["_links"]["self"]["title"]).to eq "Title"
          expect(subject["_links"]["self"]["href"]).to eq "http://url"
        end

        it "includes an embedded list of triggered webhooks" do
          expect(subject["_embedded"]["triggeredWebhooks"]).to be_instance_of(Array)
        end
      end
    end
  end
end
