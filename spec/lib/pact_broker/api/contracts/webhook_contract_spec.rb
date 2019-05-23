require 'pact_broker/api/contracts/webhook_contract'
require 'pact_broker/api/decorators/webhook_decorator'

module PactBroker
  module Api
    module Contracts
      describe WebhookContract do
        let(:json) { load_fixture 'webhook_valid_with_pacticipants.json' }
        let(:hash) { JSON.parse(json) }
        let(:webhook) { PactBroker::Api::Decorators::WebhookDecorator.new(Domain::Webhook.new).from_json(json) }
        let(:subject) { WebhookContract.new(webhook) }
        let(:matching_hosts) { ['foo'] }
        let(:consumer) { double("consumer") }
        let(:provider) { double("provider") }

        def valid_webhook_with
          hash = load_json_fixture 'webhook_valid_with_pacticipants.json'
          yield hash
          hash.to_json
        end

        describe "errors" do
          before do
            PactBroker.configuration.webhook_http_method_whitelist = webhook_http_method_whitelist
            PactBroker.configuration.webhook_host_whitelist = webhook_host_whitelist
            allow(PactBroker::Webhooks::CheckHostWhitelist).to receive(:call).and_return(whitelist_matches)
            allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).with("Foo").and_return(consumer)
            allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).with("Bar").and_return(provider)
            subject.validate(hash)
          end

          let(:webhook_http_method_whitelist) { ['POST'] }
          let(:whitelist_matches) { ['foo'] }
          let(:webhook_host_whitelist) { [] }

          context "with valid fields" do
            it "is empty" do
              expect(subject.errors).to be_empty
            end
          end

          context "with a nil consumer name" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['consumer']['name'] = nil
              end
            end

            it "contains an error" do
              expect(subject.errors[:'consumer.name']).to eq ["can't be blank"]
            end
          end

          context "with no consumer name key" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['consumer'].delete('name')
              end
            end

            # I'd prefer this to be "is missing". Isn't the whole point of dry validation
            # that you can distingush between keys being missing and values being missing? FFS.
            it "contains an error" do
              expect(subject.errors[:'consumer.name']).to eq ["can't be blank"]
            end
          end

          context "with no consumer" do
            let(:json) do
              valid_webhook_with do |hash|
                hash.delete('consumer')
              end
            end

            it "contains no errors" do
              expect(subject.errors).to be_empty
            end
          end

          context "with a consumer name that doesn't match any existing consumer" do
            let(:consumer) { nil }

            it "contains no errors" do
              expect(subject.errors[:'consumer.name']).to eq ["does not match an existing pacticipant"]
            end
          end

          context "with a nil provider name" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['provider']['name'] = nil
              end
            end

            it "contains an error" do
              expect(subject.errors[:'provider.name']).to eq ["can't be blank"]
            end
          end

          context "with no provider name key" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['provider'].delete('name')
              end
            end

            # I'd prefer this to be "is missing". Isn't the whole point of dry validation
            # that you can distingush between keys being missing and values being missing? FFS.
            it "contains an error" do
              expect(subject.errors[:'provider.name']).to eq ["can't be blank"]
            end
          end

          context "with no provider" do
            let(:json) do
              valid_webhook_with do |hash|
                hash.delete('provider')
              end
            end

            it "contains no errors" do
              expect(subject.errors).to be_empty
            end
          end

          context "with a provider name that doesn't match any existing provider" do
            let(:provider) { nil }

            it "contains no errors" do
              expect(subject.errors[:'provider.name']).to eq ["does not match an existing pacticipant"]
            end
          end

          context "with no request defined" do
            let(:json) { {}.to_json }

            it "contains an error for missing request" do
              expect(subject.errors[:request]).to eq ["can't be blank"]
            end
          end

          context "with no events defined" do
            let(:json) { {}.to_json }

            it "does not contain an error for missing event, as it will be defaulted" do
              expect(subject.errors.messages[:events]).to be nil
            end
          end

          context "with empty events" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['events'] = []
              end
            end

            it "contains an error for missing request" do
              expect(subject.errors[:events]).to eq ["size cannot be less than 1"]
            end
          end

          context "with no method" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['request'].delete('method')
              end
            end

            it "contains an error for missing method" do
              expect(subject.errors[:"request.http_method"]).to include "can't be blank"
            end
          end

          context "with an invalid method" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['request']['method'] = 'blah'
              end
            end

            it "contains an error for invalid method" do
              expect(subject.errors[:"request.http_method"]).to include "is not a recognised HTTP method"
            end
          end

          context "with an invalid scheme" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['request']['url'] = 'ftp://foo'
              end
            end

            it "contains an error for the URL" do
              expect(subject.errors[:"request.url"]).to include "scheme must be https. See /doc/webhooks#whitelist for more information."
            end
          end

          context "with an HTTP method that is not whitelisted" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['request']['method'] = 'DELETE'
              end
            end

            context "when there is only one allowed HTTP method" do
              it "contains an error for invalid method" do
                expect(subject.errors[:"request.http_method"]).to include "must be POST. See /doc/webhooks#whitelist for more information."
              end
            end

            context "when there is more than one allowed HTTP method", pending: "need to work out how to dynamically create this message" do
              let(:webhook_http_method_whitelist) { ['POST', 'GET'] }

              it "contains an error for invalid method" do
                expect(subject.errors[:"request.http_method"]).to include "must be one of POST, GET"
              end
            end
          end

          context "when the host whitelist is empty" do
            it "does not attempt to validate the host" do
              expect(PactBroker::Webhooks::CheckHostWhitelist).to_not have_received(:call)
            end
          end

          context "when the host whitelist is populated" do
            let(:webhook_host_whitelist) { [/foo/, "bar"] }

            it "validates the host" do
              expect(PactBroker::Webhooks::CheckHostWhitelist).to have_received(:call).with("some.url", webhook_host_whitelist)
            end

            context "when the host does not match the whitelist" do
              let(:whitelist_matches) { [] }

              it "contains an error", pending: "need to work out how to do dynamic messages" do
                expect(subject.errors[:"request.url"]).to include "host must be in the whitelist /foo/, \"bar\" . See /doc/webhooks#whitelist for more information."
              end
            end
          end

          context "with no URL" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['request'].delete('url')
              end
            end

            it "contains an error for missing URL" do
              expect(subject.errors[:"request.url"]).to include "can't be blank"
            end
          end

          context "with an invalid URL" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['request']['url'] = 'bl ah'
              end
            end

            it "contains an error for invalid URL" do
              expect(subject.errors[:"request.url"]).to eq ["is not a valid URL eg. http://example.org"]
            end
          end

          context "with an URL missing a scheme" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['request']['url'] = 'blah'
              end
            end

            it "contains an error for invalid URL" do
              expect(subject.errors[:"request.url"]).to eq ["is not a valid URL eg. http://example.org"]
            end
          end

          context "with a URL that has templated parameters in it" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['request']['url'] = 'https://foo/commits/${pactbroker.consumerVersionNumber}'
              end
            end

            it "is empty" do
              expect(subject.errors).to be_empty
            end
          end

          context "with a URL that has templated parameters in the host" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['request']['url'] = 'https://${pactbroker.consumerVersionNumber}/commits'
              end
            end

            it "contains an error" do
              expect(subject.errors[:"request.url"]).to eq ["cannot have a template parameter in the host"]
            end
          end

          context "when enabled is not a boolean", pending: "I can't work out why this doesn't work" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['enabled'] = 'foo'
              end
            end

            it "contains an error" do
              expect(subject.errors[:enabled]).to eq ["cannot have a template parameter in the host"]
            end
          end
        end
      end
    end
  end
end
