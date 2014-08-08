require 'spec_helper'
require 'pact_broker/models/webhook'

module PactBroker

  module Models

    describe Webhook do

      let(:consumer) { Pacticipant.new(name: 'Consumer')}
      let(:provider) { Pacticipant.new(name: 'Provider')}
      let(:request) { instance_double(PactBroker::Models::WebhookRequest, execute: nil)}
      subject { Webhook.new(request: request, consumer: consumer, provider: provider,) }

      describe "#validate" do
        let(:errors) { ['errors'] }


        context "when the request is not present" do
          let(:request) { nil }

          it "returns an error message" do
            expect(subject.validate).to include "Missing required attribute 'request'"
          end
        end

        context "when the request is present" do

          it "validates the request" do
            expect(request).to receive(:validate).and_return(errors)
            expect(subject.validate).to eq errors
          end
        end
      end

      describe "description" do
        it "returns a description of the webhook" do
          expect(subject.description).to eq "A webhook for the pact between Consumer and Provider"
        end
      end

      describe "execute" do

        it "executes the request" do
          expect(request).to receive(:execute)
          subject.execute
        end

        context "when successful" do
          it "logs before and after" do
            expect(PactBroker.logger).to receive(:info).with(/Executing/)
            expect(PactBroker.logger).to receive(:info).with(/Successfully/)
            subject.execute
          end
        end

        context "when an error occurs" do

          class WebhookTestError < StandardError; end

          before do
            allow(request).to receive(:execute).and_raise(WebhookTestError.new("blah"))
          end

          it "logs the error" do
            allow(PactBroker.logger).to receive(:error)
            expect(PactBroker.logger).to receive(:error).with(/Error.*WebhookTestError.*blah/)
            begin
              subject.execute
            rescue WebhookTestError => e
              # do nothing
            end
          end

          it "re-raises the error" do
            expect { subject.execute }.to raise_error WebhookTestError
          end
        end
      end
    end

  end

end
