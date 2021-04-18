require 'pact_broker/api/resources/released_version'

module PactBroker
  module Api
    module Resources
      describe ReleasedVersion do
        before do
          allow_any_instance_of(described_class).to receive(:released_version_service).and_return(released_version_service)
          allow(released_version_service).to receive(:find_by_uuid).and_return(released_version)
          allow(PactBroker::Api::Decorators::ReleasedVersionDecorator).to receive(:new).and_return(decorator)
        end

        let(:released_version) { instance_double("PactBroker::Deployments::ReleasedVersion") }
        let(:parsed_released_version) { double("parsed released_version") }
        let(:released_version_service) { class_double("PactBroker::Deployments::ReleasedVersionService").as_stubbed_const }
        let(:path) { "/released-versions/#{uuid}" }
        let(:uuid) { "12345678" }
        let(:rack_headers) do
          {
            "HTTP_ACCEPT" => "application/hal+json"
          }
        end
        let(:decorator) do
          instance_double("PactBroker::Api::Decorators::ReleasedVersionDecorator",
            to_json: "response",
            from_json: parsed_released_version
          )
        end

        describe "GET" do
          subject { get(path, nil, rack_headers) }

          it "attempts to find the ReleasedVersion" do
            expect(PactBroker::Deployments::ReleasedVersionService).to receive(:find_by_uuid).with(uuid)
            subject
          end

          context "when the released_version does not exist" do
            let(:released_version) { nil }

            it { is_expected.to be_a_404_response }
          end

          context "when the ReleasedVersion exists" do
            it "generates a JSON representation of the ReleasedVersion" do
              expect(PactBroker::Api::Decorators::ReleasedVersionDecorator).to receive(:new).with(released_version)
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
