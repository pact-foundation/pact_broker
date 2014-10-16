require 'spec_helper'
require 'pact_broker/api/contracts/webhook_contract'
require 'pact_broker/api/decorators/webhook_decorator'

module PactBroker
  module Api
    module Contracts
      describe WebhookContract do

        let(:json) { load_fixture 'webhook_valid.json' }
        let(:webhook) { PactBroker::Api::Decorators::WebhookDecorator.new(Models::Webhook.new).from_json(json) }
        let(:subject) { WebhookContract.new(webhook) }

        def valid_webhook_with
          hash = load_json_fixture 'webhook_valid.json'
          yield hash
          hash.to_json
        end

        describe "errors" do

          before do
            subject.validate
          end

          context "with valid fields" do
            it "is empty" do
              expect(subject.errors.any?).to be false
            end
          end

          context "with no request defined" do

            let(:json) { {}.to_json }

            it "contains an error for missing request" do
              subject.validate
              expect(subject.errors[:request]).to eq ["can't be blank"]
            end
          end

          context "with no method" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['request'].delete('method')
              end
            end

            it "contains an error for missing method" do
              expect(subject.errors[:"request.http_method"]).to eq ["can't be blank"]
            end
          end

          context "with an invalid method" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['request']['method'] = 'blah'
              end
            end

            it "contains an error for invalid method" do
              expect(subject.errors[:"request.method"]).to eq ["is not a recognised HTTP method"]
            end
          end

          context "with no URL" do
            let(:json) do
              valid_webhook_with do |hash|
                hash['request'].delete('url')
              end
            end

            it "contains an error for missing URL" do
              expect(subject.errors[:"request.url"]).to eq ["can't be blank"]
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
        end

      end
    end
  end
end