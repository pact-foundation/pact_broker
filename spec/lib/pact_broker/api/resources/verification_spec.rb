module PactBroker
  module Api
    module Resources
      describe Verification do
        before do
          allow_any_instance_of(described_class).to receive(:verification_service).and_return(verification_service)
          allow(verification_service).to receive(:find).and_return(verification)
          allow(PactBroker::Api::Decorators::VerificationDecorator).to receive(:new).and_return(decorator)
        end

        let(:verification) { instance_double("PactBroker::Domain::Verification") }
        let(:parsed_verification) { double("parsed verification") }
        let(:verification_service) { class_double("PactBroker::Verifications::Service").as_stubbed_const }
        let(:path) { "/pacts/provider/Bar/consumer/Foo/pact-version/1/verification-results/2" }

        let(:rack_headers) do
          {
            "HTTP_ACCEPT" => "application/hal+json"
          }
        end

        let(:decorator) do
          instance_double("PactBroker::Api::Decorators::VerificationDecorator",
            to_json: "response",
            from_json: parsed_verification
          )
        end

        describe "GET" do
          let(:identifier_params) { { consumer_name: "Foo", provider_name: "Bar", pact_version_sha: "1", verification_number: "2" } }

          subject { get(path, nil, rack_headers) }

          it "finds the Verification" do
            expect(PactBroker::Verifications::Service).to receive(:find).with(hash_including(identifier_params))
            subject
          end

          context "when the verification does not exist" do
            let(:verification) { nil }

            it { is_expected.to be_a_404_response }
          end

          context "when someone tries to get all the verifications for a pact" do
            let(:path) { "/pacts/provider/Bar/consumer/Foo/pact-version/1/verification-results/all" }

            it "does not attempt to find the verification" do
              expect(PactBroker::Verifications::Service).to_not receive(:find)
              subject
            end

            it "tells them to use the matrix" do
              expect(subject.status).to eq 404
              expect(subject.body).to include "Matrix"
            end
          end

          context "when the verification number specified is not a number" do
            let(:path) { "/pacts/provider/Bar/consumer/Foo/pact-version/1/verification-results/5*5" }

            it "does not attempt to find the verification" do
              expect(PactBroker::Verifications::Service).to_not receive(:find)
              subject
            end

            its(:status) { is_expected.to eq 404 }
          end

          context "when the Verification exists" do
            it "generates a JSON representation of the Verification" do
              expect(PactBroker::Api::Decorators::VerificationDecorator).to receive(:new).with(verification)
              expect(decorator).to receive(:to_json).with(user_options: hash_including(base_url: "http://example.org"))
              subject
            end

            it { is_expected.to be_a_hal_json_success_response }

            it "includes the JSON representation in the response body" do
              expect(subject.body).to eq "response"
            end
          end
        end
      end
    end
  end
end
