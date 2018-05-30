require 'spec_helper'
require 'pact_broker/api/resources/webhook_execution'

module PactBroker
  module Api
    module Resources

      describe WebhookExecution do

        describe "POST" do

          before do
            allow(PactBroker::Webhooks::Service).to receive(:find_by_uuid).and_return(webhook)
            allow(PactBroker::Webhooks::Service).to receive(:webhook_blacklisted?).and_return(blacklisted)
          end

          let(:blacklisted) { false }

          subject { post "/webhooks/some-uuid/execute"}

          context "when the webhook does not exist" do
            let(:webhook) { nil }

            it "returns a 404" do
              subject
              expect(last_response).to be_a_404_response
            end
          end

          context "when the webhook does exist" do
            let(:success) { true }
            let(:execution_result) { double('execution_result', success?: success, to_json: json)}
            let(:json) { {some: 'json'}.to_json }
            let(:webhook) { double("webhook", consumer_name: consumer_name, provider_name: provider_name) }
            let(:decorator) { instance_double(PactBroker::Api::Decorators::WebhookExecutionResultDecorator, to_json: json)}
            let(:pact) { instance_double("PactBroker::Domain::Pact") }
            let(:consumer_name) { "foo" }
            let(:provider_name) { "bar" }

            before do
              allow(PactBroker::Webhooks::Service).to receive(:execute_webhook_now).and_return(execution_result)
              allow(PactBroker::Api::Decorators::WebhookExecutionResultDecorator).to receive(:new).and_return(decorator)
              allow(PactBroker::Pacts::Service).to receive(:find_latest_pact).and_return(pact)
            end

            it "finds the latest pact for the webhook" do
              expect(PactBroker::Pacts::Service).to receive(:find_latest_pact).with(consumer_name: consumer_name, provider_name: provider_name)
              subject
            end

            it "executes the webhook" do
              expect(PactBroker::Webhooks::Service).to receive(:execute_webhook_now).with(webhook, pact)
              subject
            end

            context "when execution is successful" do
              it "returns a 200 JSON response" do
                subject
                expect(last_response).to be_a_hal_json_success_response
              end

              it "generates a JSON response body for the execution result" do
                expect(decorator).to receive(:to_json).with(user_options: { base_url: 'http://example.org', webhook: webhook })
                subject
              end

              it "includes the execution result JSON in the body" do
                subject
                expect(last_response.body).to eq json
              end
            end

            context "when execution is not successful" do
              let(:success) { false }
              it "returns a 500 JSON response" do
                subject
                expect(last_response.status).to eq 500
              end

              it "includes the execution result JSON in the body" do
                subject
                expect(last_response.body).to eq json
              end
            end

            context "when the webhook host is blacklisted" do
              let(:blacklisted) { true }

              it "returns a 400" do
                subject
                expect(last_response.status).to eq 400
              end

              it "returns a 400" do
                subject
                expect(JSON.parse(last_response.body)['errors']).to eq "webhook.request.url" => "is blacklisted"
              end
            end
          end
        end
      end
    end
  end
end
