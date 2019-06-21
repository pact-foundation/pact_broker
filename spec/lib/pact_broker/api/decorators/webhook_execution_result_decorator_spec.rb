require 'spec_helper'
require 'pact_broker/api/decorators/webhook_execution_result_decorator'

module PactBroker
  module Api
    module Decorators
      describe WebhookExecutionResultDecorator do

        describe "to_json" do

          let(:webhook_execution_result) { PactBroker::Webhooks::WebhookExecutionResult.new(request, response, logs, error)}
          let(:logs) { "logs" }
          let(:headers) { { "Something" => ["blah", "thing"]} }
          let(:request) do
            req = Net::HTTP::Get.new("http://example.org?foo=bar")
            req['Foo'] = ['bar', 'wiffle']
            req.body = { foo: 'bar' }.to_json
            req
          end
          let(:response) { double('http_response', code: '200', body: response_body, to_hash: headers) }
          let(:response_body) { 'body' }
          let(:error) { nil }
          let(:webhook) { instance_double(PactBroker::Domain::Webhook, uuid: uuid) }
          let(:uuid) { 'some-uuid' }
          let(:show_response) { true }
          let(:json) {
            WebhookExecutionResultDecorator.new(webhook_execution_result)
            .to_json(user_options: { resource_url: 'http://resource-url', base_url: 'http://example.org', webhook: webhook, show_response: show_response })
          }

          let(:subject) { JSON.parse(json, symbolize_names: true)}

          it "includes a link to execute the webhook again" do
            expect(subject[:_links][:'try-again'][:href]).to eq 'http://resource-url'
          end

          context "when there is a uuid" do
            it "include a link to the webhook" do
              expect(subject[:_links][:webhook][:href]).to eq 'http://example.org/webhooks/some-uuid'
            end
          end

          context "when there is a not uuid because this is an unsaved webhook" do
            let(:uuid) { nil }

            it "does not includes a link to the webhook" do
              expect(subject[:_links]).to_not have_key(:webhook)
            end
          end


          context "when there is an error" do
            let(:error) { double('error', message: 'message', backtrace: ['blah','blah']) }

            it "includes the message" do
              expect(subject[:error][:message]).to eq 'message'
            end
          end

          context "when there is a request" do
            it "includes the request URL" do
              expect(subject[:request][:url]).to eq "http://example.org?foo=bar"
            end

            it "includes the request headers" do
              expect(subject[:request][:headers][:'foo']).to eq "bar, wiffle"
            end

            context "when the request body is JSON" do
              it "includes the request body as JSON" do
                expect(subject[:request][:body]).to include( foo: 'bar' )
              end
            end

            context "when the request body is not json" do
              before do
                request.body = "<xml></xml>"
              end

              it "includes the request body as a String" do
                expect(subject[:request][:body]).to eq "<xml></xml>"
              end
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
              expect(subject[:response][:body]).to eq response_body
            end

            context "when the response body is JSON" do
              let(:response_body_hash) { {some: 'json'} }
              let(:response_body) { response_body_hash.to_json }
              it "returns the response as JSON" do
                expect(subject[:response][:body]).to eq response_body_hash
              end
            end
          end

          context "when show_response is false" do
            let(:show_response) { false }

            it "does not include the response" do
              expect(subject).to_not have_key(:response)
            end

            it "includes a message about why the response is hidden" do
              expect(subject[:message]).to match /security purposes/
            end
          end
        end
      end
    end
  end
end
