require 'spec_helper'
require 'pact_broker/api/decorators/webhooks_decorator'

module PactBroker
  module Api
    module Decorators
      describe WebhooksDecorator do

        let(:webhook) do
          instance_double(Models::Webhook, uuid: 'some-uuid', description: 'description')
        end

        let(:webhooks) { [webhook] }

        describe "to_json" do

          let(:json) { WebhooksDecorator.new(webhooks).to_json(base_url: 'http://example.org') }

          subject { JSON.parse(json, symbolize_names: true) }

          it "includes a list of links to the webhooks" do
            expect(subject[:_links][:webhooks]).to be_instance_of(Array)
            expect(subject[:_links][:webhooks].first).to eq title: 'description', href: 'http://example.org/webhooks/some-uuid'
          end

        end

      end
    end
  end
end