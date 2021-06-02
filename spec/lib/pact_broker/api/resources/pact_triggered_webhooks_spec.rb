require "pact_broker/api/resources/pact_triggered_webhooks"

module PactBroker
  module Api
    module Resources
      describe PactTriggeredWebhooks do
        describe "GET" do
          before do
            allow(Decorators::TriggeredWebhooksDecorator).to receive(:new).and_return(decorator)
            allow_any_instance_of(PactTriggeredWebhooks).to receive(:webhook_service).and_return(webhook_service)
            allow_any_instance_of(PactTriggeredWebhooks).to receive(:pact).and_return(pact)
            allow(webhook_service).to receive(:find_triggered_webhooks_for_pact).and_return(triggered_webhooks)
          end

          let(:decorator) { instance_double(Decorators::TriggeredWebhooksDecorator, to_json: "json") }
          let(:webhook_service) { class_double(PactBroker::Webhooks::Service) }
          let(:pact) { instance_double(PactBroker::Domain::Pact, name: "The pact") }
          let(:triggered_webhooks) { double("triggered_webhooks") }
          let(:path) { "/pacts/provider/bar/consumer/foo/version/1/triggered-webhooks" }

          subject { get path; last_response }

          context "when the pact exists" do
            it { is_expected.to be_a_hal_json_success_response }

            it "finds the triggered webhooks for the pact" do
              expect(webhook_service).to receive(:find_triggered_webhooks_for_pact)
              subject
            end

            it "generates the JSON response body" do
              expect(Decorators::TriggeredWebhooksDecorator).to receive(:new).with(triggered_webhooks)
              expect(decorator).to receive(:to_json) do | options |
                expect(options[:user_options]).to include(resource_title: "Webhooks triggered by the publication of the the pact")
                expect(options[:user_options]).to include(resource_url: "http://example.org#{path}")
              end
              subject
            end

            it "returns the generated JSON response body" do
              expect(subject.body).to eq "json"
            end
          end

          context "when the pact does not exist" do
            let(:pact) { nil }

            it { is_expected.to be_a_404_response }
          end
        end
      end
    end
  end
end
