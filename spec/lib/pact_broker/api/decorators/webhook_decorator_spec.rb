require 'pact_broker/api/decorators/webhook_decorator'
require 'pact_broker/models/webhook'

module PactBroker
  module Api
    module Decorators
      describe WebhookDecorator do

        let(:hash) do
          {
            request: {
              method: 'POST',
              url: 'http://example.org/hook',
              headers: {:'Content-Type' => 'application/json'},
              body: { some: 'body' }
            },

            _embedded: {
              consumer: {
                name: 'Consumer',
                :_links => {
                  :self => {
                    :href=>"http://example.org/pacticipants/Consumer"
                    }
                  }
                },
                provider: {
                  name: 'Provider',
                  :_links => {
                    :self => {
                      :href=>"http://example.org/pacticipants/Provider"
                    }
                  }
                }
              },

            _links: {
              :self => {
                href: 'http://example.org/webhooks/some-uuid'
              }
            }
          }
        end

        let(:webhook_request) do
          Models::WebhookRequest.new(hash[:request])
        end

        let(:consumer) { Models::Pacticipant.new(name: 'Consumer') }
        let(:provider) { Models::Pacticipant.new(name: 'Provider') }

        let(:webhook) do
          Models::Webhook.new(request: webhook_request, uuid: 'some-uuid', consumer: consumer, provider: provider)
        end

        subject { WebhookDecorator.new(webhook) }

        describe "to_json" do

          let(:parsed_json) { JSON.parse(subject.to_json(base_url: 'http://example.org'), symbolize_names: true)}

          it "serialises the webhook to JSON" do
            expect(parsed_json).to eq hash
          end

        end

        describe "from_json" do
          let(:json) { hash.to_json }
          let(:webhook) { Models::Webhook.new }
          let(:parsed_object) { subject.from_json(json) }

          it "parses the request method" do
            expect(parsed_object.request.method).to eq 'POST'
          end

          it "parses the request URL" do
            expect(parsed_object.request.url).to eq 'http://example.org/hook'
          end

          it "parses the request headers" do
            expect(parsed_object.request.headers).to eq 'Content-Type' => 'application/json'
          end

          it "parses the request body" do
            expect(parsed_object.request.body).to eq 'some' => 'body'
          end
        end

      end
    end
  end
end