require 'spec_helper'
require 'pact_broker/api/resources/all_webhooks'

module PactBroker::Api

  module Resources

    describe AllWebhooks do

      describe "GET" do

        subject { get "/webhooks" }

        let(:webhooks) { [double('webhook')]}
        let(:decorator) { double(Decorators::WebhooksDecorator, to_json: json)}
        let(:json) { {some: 'json'}.to_json }

        before do
          allow(Decorators::WebhooksDecorator).to receive(:new).and_return(decorator)
          allow(PactBroker::Webhooks::Service).to receive(:find_all).and_return(webhooks)
        end

        it "returns a 200 HAL JSON response" do
          subject
          expect(last_response).to be_a_hal_json_success_response
        end

        it "generates a JSON representation of the webhook" do
          expect(Decorators::WebhooksDecorator).to receive(:new).with(webhooks)
          expect(decorator).to receive(:to_json).with(user_options: instance_of(Decorators::DecoratorContext))
          subject
        end

        it "includes the JSON representation in the response body" do
          subject
          expect(last_response.body).to eq json
        end

      end

    end
  end

end
