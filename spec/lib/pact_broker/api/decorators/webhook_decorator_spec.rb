require 'pact_broker/api/decorators/webhook_decorator'
require 'pact_broker/domain/webhook'

module PactBroker
  module Api
    module Decorators
      describe WebhookDecorator do
        let(:headers) { { :'Content-Type' => 'application/json' } }
        let(:request) do
          {
            method: 'POST',
            url: 'http://example.org/hook',
            headers: headers,
            body: { some: 'body' }
          }
        end

        let(:webhook_request) do
          Webhooks::WebhookRequestTemplate.new(request)
        end

        let(:consumer) { Domain::Pacticipant.new(name: 'Consumer') }
        let(:provider) { Domain::Pacticipant.new(name: 'Provider') }
        let(:event)    { Webhooks::WebhookEvent.new(name: 'something_happened') }
        let(:created_at) { DateTime.now }
        let(:updated_at) { created_at + 1 }

        let(:webhook) do
          Domain::Webhook.new(
            request: webhook_request,
            uuid: 'some-uuid',
            consumer: consumer,
            provider: provider,
            events: [event],
            created_at: created_at,
            updated_at: updated_at
          )
        end

        subject { WebhookDecorator.new(webhook) }

        describe 'to_json' do
          let(:parsed_json) { JSON.parse(subject.to_json(user_options: { base_url: 'http://example.org' }), symbolize_names: true) }

          it 'includes the request' do
            expect(parsed_json[:request]).to eq request
          end

          it 'includes the consumer' do
            expect(parsed_json[:consumer]).to eq name: "Consumer"
          end

          it 'includes the provider' do
            expect(parsed_json[:provider]).to eq name: "Provider"
          end

          it 'includes a link to the consumer' do
            expect(parsed_json[:_links][:'pb:consumer'][:name]).to eq 'Consumer'
            expect(parsed_json[:_links][:'pb:consumer'][:href]).to eq 'http://example.org/pacticipants/Consumer'
          end

          it 'includes a link to the provider' do
            expect(parsed_json[:_links][:'pb:provider'][:name]).to eq 'Provider'
            expect(parsed_json[:_links][:'pb:provider'][:href]).to eq 'http://example.org/pacticipants/Provider'
          end

          it 'includes a link to itself' do
            expect(parsed_json[:_links][:self][:href]).to eq 'http://example.org/webhooks/some-uuid'
            expect(parsed_json[:_links][:self][:title]).to_not be_nil
          end

          it 'includes a link to its parent collection' do
            expect(parsed_json[:_links][:'pb:pact-webhooks'][:href]).to_not be_nil
          end

          it 'includes a link to the webhooks resource' do
            expect(parsed_json[:_links][:'pb:webhooks'][:href]).to_not be_nil
          end

          it 'includes a link to execute the webhook directly' do
            expect(parsed_json[:_links][:'pb:execute'][:href]).to eq 'http://example.org/webhooks/some-uuid/execute'
          end

          it 'includes the events' do
            expect(parsed_json[:events].first).to eq name: 'something_happened'
          end

          it 'includes timestamps' do
            expect(parsed_json[:createdAt]).to eq created_at.xmlschema
            expect(parsed_json[:updatedAt]).to eq updated_at.xmlschema
          end

          context 'when the headers are empty' do
            let(:headers) { nil }
            it 'does not include the headers' do
              expect(parsed_json[:request]).to_not have_key :headers
            end
          end

          context 'when there is no consumer' do
            before do
              webhook.consumer = nil
            end

            it 'does not include the consumer relation' do
              expect(parsed_json[:_links][:'pb:consumer']).to be nil
            end

            it 'does not include the pact webhooks relation' do
              expect(parsed_json[:_links][:'pb:pact-webhooks']).to be nil
            end
          end

          context 'when there is no provider' do
            before do
              webhook.provider = nil
            end

            it 'does not include the provider relation' do
              expect(parsed_json[:_links][:'pb:provider']).to be nil
            end

            it 'does not include the pact webhooks relation' do
              expect(parsed_json[:_links][:'pb:pact-webhooks']).to be nil
            end
          end

          context 'when the headers contain sensitve information' do
            let(:headers) { { 'Authorization' => 'foo' } }
            it 'redacts them' do
              expect(parsed_json[:request][:headers][:'Authorization']).to eq "**********"
            end
          end

          context 'when there is no sensitive data in the url' do
            it 'is shown as is' do
              expect(parsed_json[:request][:url]).to eq "http://example.org/hook"
            end
          end

          context 'when the url contains a slack token' do
            let(:request) do
              {
                method: 'POST',
                url: 'https://hooks.slack.com/services/aaa/bbb/ccc',
                headers: headers,
                body: { some: 'body' }
              }
            end

            let(:parsed_json) { JSON.parse(subject.to_json(user_options: { base_url: 'https://hooks.slack.com/services/aaa/bbb/ccc' }), symbolize_names: true) }

            it 'redacts them' do
              expect(parsed_json[:request][:url]).to eq "https://hooks.slack.com/services/aaa/bbb/redacted"
            end
          end

          context 'when the url contains a token param' do
            let(:request) do
              {
                method: 'POST',
                url: 'https://secure.server.com/?token=thatneedstobehidden',
                headers: headers,
                body: { some: 'body' }
              }
            end

            let(:parsed_json) { JSON.parse(subject.to_json(user_options: { base_url: 'https://secure.server.com/?token=thatneedstobehidden' }), symbolize_names: true) }

            it 'redacts them' do
              expect(parsed_json[:request][:url]).to eq "https://secure.server.com/?token=redacted"
            end
          end
          
          context 'when the url contains multiple params including a token param at the start of the url' do
            let(:request) do
              {
                method: 'POST',
                url: 'https://secure.server.com/?token=thatwedont&param=thatwewant',
                headers: headers,
                body: { some: 'body' }
              }
            end

            let(:parsed_json) { JSON.parse(subject.to_json(user_options: { base_url: 'https://secure.server.com/?token=thatwedont&param=thatwewant' }), symbolize_names: true) }

            it 'redacts only the token' do
              expect(parsed_json[:request][:url]).to eq "https://secure.server.com/?token=redacted&param=thatwewant"
            end
          end
          
          context 'when the url contains multiple params including a token param at the end of the url' do
            let(:request) do
              {
                method: 'POST',
                url: 'https://secure.server.com/?param=thatwewant&token=thatwedont',
                headers: headers,
                body: { some: 'body' }
              }
            end

            let(:parsed_json) { JSON.parse(subject.to_json(user_options: { base_url: 'https://secure.server.com/?param=thatwewant&token=thatwedont' }), symbolize_names: true) }

            it 'redacts only the token' do
              expect(parsed_json[:request][:url]).to eq "https://secure.server.com/?param=thatwewant&token=redacted"
            end
          end
        end

        describe 'from_json' do
          let(:hash) { { request: request, events: [event] } }
          let(:event) { {name: 'something_happened'} }
          let(:json) { hash.to_json }
          let(:webhook) { Domain::Webhook.new }
          let(:parsed_object) { subject.from_json(json) }

          it 'parses the request method' do
            expect(parsed_object.request.method).to eq 'POST'
          end

          it 'parses the request URL' do
            expect(parsed_object.request.url).to eq 'http://example.org/hook'
          end

          it 'parses the request headers' do
            expect(parsed_object.request.headers).to eq 'Content-Type' => 'application/json'
          end

          it 'parses the request body' do
            expect(parsed_object.request.body).to eq 'some' => 'body'
          end

          it 'parses the events' do
            expect(parsed_object.events.size).to eq 1
            expect(parsed_object.events.first.name).to eq 'something_happened'
          end

          context "when no events are specified" do
            let(:hash) { { request: request } }
            let(:webhook) { Domain::Webhook.new }

            it "defaults to a single contract_changed event for backwards compatibility" do
              expect(parsed_object.events.size).to eq 1
              expect(parsed_object.events.first.name).to eq PactBroker::Webhooks::WebhookEvent::DEFAULT_EVENT_NAME
            end
          end
        end  
      end
    end
  end
end