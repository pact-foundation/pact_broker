require 'spec_helper'
require 'pact_broker/models/webhook'

module PactBroker

  module Models

    describe Webhook do

      describe "#validate" do
        let(:request) { instance_double(PactBroker::Models::WebhookRequest)}
        let(:errors) { ['errors'] }

        subject { Webhook.new(request: request) }

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
    end

  end

end
