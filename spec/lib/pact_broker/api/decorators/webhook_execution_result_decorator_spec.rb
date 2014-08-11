require 'spec_helper'
require 'pact_broker/api/decorators/webhook_execution_result_decorator'

module PactBroker
  module Api
    module Decorators
      describe WebhookExecutionResultDecorator do

        describe "to_json" do

          let(:webhook_execution_result) { PactBroker::Models::WebhookExecutionResult.new(response, error)}
          let(:headers) { { "Something" => ["blah", "thing"]} }
          let(:response) { double('http_response', code: '200', body: 'body', to_hash: headers) }
          let(:error) { nil }
          let(:webhook) { instance_double(PactBroker::Models::Webhook, uuid: 'some-uuid')}
          let(:json) {
            WebhookExecutionResultDecorator.new(webhook_execution_result)
            .to_json(base_url: 'http://example.org', webhook: webhook)
          }

          let(:subject) { JSON.parse(json, symbolize_names: true)}

          it "includes a link to execute the webhook again" do
            expect(subject[:_links][:'try-again'][:href]).to eq 'http://example.org/webhooks/some-uuid/execute'
          end

          it "includes a link to the webhook" do
            expect(subject[:_links][:webhook][:href]).to eq 'http://example.org/webhooks/some-uuid'
          end

          context "when there is an error" do
            let(:error) { double('error', message: 'message', backtrace: ['blah','blah']) }

            it "includes the message" do
              expect(subject[:error][:message]).to eq 'message'
            end

            it "includes the backtrace" do
              expect(subject[:error][:backtrace]).to eq ['blah','blah']
            end
          end

          context "when there is a response" do
            it "includes the response code" do
              expect(subject[:response][:status]).to eq 200
            end

            it "includes the response headers" do
              expect(subject[:response][:headers]).to eq :'Something' => "blah, thing"
            end
            it "includes the response body" do
              expect(subject[:response][:body]).to eq 'body'
            end
          end
        end

      end
    end
  end
end