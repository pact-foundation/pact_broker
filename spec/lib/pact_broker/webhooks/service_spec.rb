require 'spec_helper'
require 'pact_broker/webhooks/service'
require 'pact_broker/webhooks/triggered_webhook'
require 'pact_broker/webhooks/webhook_event'
require 'webmock/rspec'
require 'sucker_punch/testing/inline'
require 'pact_broker/webhooks/execution_configuration'

module PactBroker
  module Webhooks
    describe Service do
      before do
        allow(Service).to receive(:logger).and_return(logger)
      end

      let(:logger) { double('logger').as_null_object }

      describe "validate - integration test" do
        let(:invalid_webhook) { PactBroker::Domain::Webhook.new }

        context "with no uuid" do
          subject { Service.errors(invalid_webhook) }

          it "does not contain an error for the uuid" do
            expect(subject.messages).to_not have_key('uuid')
          end
        end

        context "with a uuid" do
          subject { Service.errors(invalid_webhook, '') }

          it "merges the uuid errors with the webhook errors" do
            expect(subject.messages['uuid'].first).to include "can only contain"
          end
        end
      end

      describe ".valid_uuid_format?" do
        it 'does something' do
          expect(Service.valid_uuid_format?("_-bcdefghigHIJKLMNOP")).to be true
          expect(Service.valid_uuid_format?("HIJKLMNOP")).to be false
          expect(Service.valid_uuid_format?("abcdefghigHIJKLMNOP\\")).to be false
          expect(Service.valid_uuid_format?("abcdefghigHIJKLMNOP#")).to be false
          expect(Service.valid_uuid_format?("abcdefghigHIJKLMNOP$")).to be false
        end
      end

      describe ".delete_by_uuid" do
        before do
          td.create_pact_with_hierarchy
            .create_webhook
            .create_triggered_webhook
        end

        subject { Service.delete_by_uuid td.webhook.uuid }

        it "deletes the webhook" do
          expect { subject }.to change {
            Webhook.count
          }.by(-1)
        end
      end

      describe ".update_by_uuid" do
        before do
          allow_any_instance_of(PactBroker::Webhooks::Repository).to receive(:find_by_uuid).and_return(existing_webhook)
        end

        let(:request) { PactBroker::Webhooks::WebhookRequestTemplate.new(password: existing_password, headers: headers)}
        let(:existing_password) { nil }
        let(:headers) { {} }
        let(:existing_webhook) { PactBroker::Domain::Webhook.new(request: request) }
        let(:params) do
          {
            'request' => {
              'url' => "http://url"
            }
          }
        end

        subject { Service.update_by_uuid("1234", params) }

        it "sends through the params to the repository" do
          updated_webhook = nil
          allow_any_instance_of(PactBroker::Webhooks::Repository).to receive(:update_by_uuid) do | instance, uuid, webhook |
            updated_webhook = webhook
            true
          end
          subject
          expect(updated_webhook.request.url).to eq 'http://url'
        end

        context "when the webhook has a password and the incoming parameters do not contain a password" do
          let(:existing_password) { 'password' }

          it "does not overwite the password" do
            updated_webhook = nil
            allow_any_instance_of(PactBroker::Webhooks::Repository).to receive(:update_by_uuid) do | instance, uuid, webhook |
              updated_webhook = webhook
              true
            end
            subject
            expect(updated_webhook.request.password).to eq 'password'
          end
        end

        context "when the webhook has a password and the incoming parameters contain a *** password" do
          let(:existing_password) { 'password' }
          let(:params) do
            {
              'request' => {
                'url' => 'http://url',
                'password' => '*******'
              }
            }
          end

          it "does not overwite the password" do
            updated_webhook = nil
            allow_any_instance_of(PactBroker::Webhooks::Repository).to receive(:update_by_uuid) do | instance, uuid, webhook |
              updated_webhook = webhook
              true
            end
            subject
            expect(updated_webhook.request.password).to eq 'password'
          end
        end

        context "when the webhook has an authorization header and the incoming parameters contain a *** authorization header" do
          let(:headers) { { 'Authorization' => 'existing'} }
          let(:params) do
            {
              'request' => {
                'url' => "http://url",
                'headers' => {
                  'authorization' => "***********"
                }
              }
            }
          end

          it "does not overwite the authorization header" do
            updated_webhook = nil
            allow_any_instance_of(PactBroker::Webhooks::Repository).to receive(:update_by_uuid) do | instance, uuid, webhook |
              updated_webhook = webhook
              true
            end
            subject
            expect(updated_webhook.request.headers['Authorization']).to eq 'existing'
          end
        end

        context "the incoming parameters contain a password" do
          let(:params) do
            {
              'request' => {
                'password' => "updated"
              }
            }
          end

          it "updates the password" do
            updated_webhook = nil
            allow_any_instance_of(PactBroker::Webhooks::Repository).to receive(:update_by_uuid) do | instance, uuid, webhook |
              updated_webhook = webhook
              true
            end
            subject
            expect(updated_webhook.request.password).to eq 'updated'
          end
        end
      end

      describe "parameters" do
        subject { Service.parameters }

        it "returns a list of parameters and their descriptions" do
          expect(subject.first.name).to start_with "pactbroker.consumerName"
          expect(subject.first.description).to eq "the consumer name"
        end
      end
    end
  end
end
