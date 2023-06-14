require "pact_broker/api/decorators/webhook_request_template_decorator"
require "json"

module PactBroker
  module Api
    module Decorators
      describe WebhookRequestTemplateDecorator do

        let(:username) { "username" }
        let(:display_password) { "*****" }
        let(:webhook_request) do
          instance_double(
            PactBroker::Webhooks::WebhookRequestTemplate,
            username: username,
            display_password: display_password,
            method: "POST",
            url: "url",
            body: "body",
            redacted_headers: {
              "foo" => "***"
            })
        end

        let(:json) { WebhookRequestTemplateDecorator.new(webhook_request).to_json }

        subject { JSON.parse(json, symbolize_names: true)}

        describe "to_json" do

          it "includes the username" do
            expect(subject[:username]).to eq username
          end

          it "includes the username starred out" do
            expect(subject[:password]).to eq display_password
          end

          context "when there is no password" do

            let(:display_password) { nil }

            it "does not include a password key" do
              expect(subject).to_not have_key(:password)
            end
          end
        end

        describe "from_json" do
          let(:password) { "password" }
          let(:hash) do
            {
              username: username,
              password: password,
              method: "POST",
              url: "url",
              body: "body",
              headers: {}
            }
          end

          let(:json) { hash.to_json }
          let(:webhook_request) { PactBroker::Webhooks::WebhookRequestTemplate.new }

          subject { WebhookRequestTemplateDecorator.new(webhook_request).from_json(json) }

          it "reads the username" do
            expect(subject.username).to eq username
          end

          it "reads the password" do
            expect(subject.password).to eq password
          end
        end
      end
    end
  end
end
