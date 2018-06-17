require 'pact_broker/api/resources/verification_triggered_webhooks'

module PactBroker
  module Api
    module Resources
      describe VerificationTriggeredWebhooks do
        describe "GET" do
          before do
            allow(Decorators::TriggeredWebhooksDecorator).to receive(:new).and_return(decorator)
            allow_any_instance_of(VerificationTriggeredWebhooks).to receive(:webhook_service).and_return(webhook_service)
            allow_any_instance_of(VerificationTriggeredWebhooks).to receive(:verification_service).and_return(verification_service)
            allow(webhook_service).to receive(:find_triggered_webhooks_for_verification).and_return(triggered_webhooks)
          end

          let(:decorator) { instance_double(Decorators::TriggeredWebhooksDecorator, to_json: 'json') }
          let(:webhook_service) { class_double(PactBroker::Webhooks::Service) }
          let(:verification_service) { class_double(PactBroker::Verifications::Service, find: verification) }
          let(:verification) { instance_double(PactBroker::Domain::Verification, number: "1") }
          let(:triggered_webhooks) { double('triggered_webhooks') }
          let(:path) { "/pacts/provider/bar/consumer/foo/pact-version/1234/verification-results/1/triggered-webhooks" }

          subject { get path; last_response }

          it "searchs for the verification" do
            expect(verification_service).to receive(:find).with(
              hash_including(
                provider_name: "bar",
                consumer_name: "foo",
                pact_version_sha: "1234",
                verification_number: "1"
              )
            )
            subject
          end

          context "when the verification exists" do

            it "finds the triggered webhooks for the verification" do
              expect(webhook_service).to receive(:find_triggered_webhooks_for_verification)
              subject
            end

            it { is_expected.to be_a_hal_json_success_response }

            it "generates the JSON response body" do
              expect(Decorators::TriggeredWebhooksDecorator).to receive(:new).with(triggered_webhooks)
              expect(decorator).to receive(:to_json) do | options |
                expect(options[:user_options]).to include(resource_title: "Webhooks triggered by the publication of verification result 1")
                expect(options[:user_options]).to include(resource_url: "http://example.org#{path}")
              end
              subject
            end

            it "returns the generated JSON response body" do
              expect(subject.body).to eq 'json'
            end
          end

          context "when the verification does not exist" do
            let(:verification) { nil }

            it { is_expected.to be_a_404_response }
          end
        end
      end
    end
  end
end
