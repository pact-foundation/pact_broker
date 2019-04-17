require 'spec_helper'
require 'pact_broker/api/decorators/webhook_request_template_decorator'
require 'json'

module PactBroker
  module Api
    module Decorators
      describe WebhookRequestTemplateDecorator do

        let(:username) { 'username' }
        let(:display_password) { '*****' }
        let(:display_url) { 'http://example.org/hooks' }
        let(:webhook_request) do
          instance_double(
            PactBroker::Webhooks::WebhookRequestTemplate,
            username: username,
            display_password: display_password,
            method: 'POST',
            display_url: display_url,
            body: 'body',
            headers: {})
        end

        let(:json) { WebhookRequestTemplateDecorator.new(webhook_request).to_json }

        subject { JSON.parse(json, symbolize_names: true)}

        describe "to_json" do

          it "includes the username" do
            expect(subject[:username]).to eq username
          end

          it "includes the password starred out" do
            expect(subject[:password]).to eq display_password
          end

          it "includes the url displayed" do
            expect(subject[:url]).to eq display_url
          end

          context "when there is no password" do

            let(:display_password) { nil }

            it "does not include a password key" do
              expect(subject).to_not have_key(:password)
            end
          end
        end

        describe "from_json" do
          let(:password) { 'password' }
          let(:url) { 'http://example.org/hooks' }
          let(:hash) do
            {
              username: username,
              password: password,
              method: 'POST',
              url: url,
              body: 'body',
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

          it "reads the url" do
            expect(subject.url).to eq 'http://example.org/hooks'
          end
          
          context "when a slack token is in the url" do
            let(:url) { 'https://hooks.slack.com/services/aaa/bbb/ccc' }
            it "reads the token" do
              expect(subject.url).to eq url
            end
          end
          context "when a token param is in the url" do
            let(:url) { 'https://hooks.slack.com/services?param=wewanttokeep&token=wewanttohide' }
            it "reads the token" do
              expect(subject.url).to eq url
            end
          end
          context "when no sensitive info in the url" do
            let(:url) { 'http://example.org/hooks?param=something' }
            it "reads the full url" do
              expect(subject.url).to eq url
            end
          end
        end
      end
    end
  end
end
