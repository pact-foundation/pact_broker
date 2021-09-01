require 'pact_broker/api/resources/branch_version'

module PactBroker
  module Api
    module Resources
      describe BranchVersion do
        before do
          allow_any_instance_of(described_class).to receive(:branch_version_service).and_return(branch_version_service)
          allow(branch_version_service).to receive(:find_by_uuid).and_return(branch_version)
          allow(PactBroker::Api::Decorators::BranchVersionDecorator).to receive(:new).and_return(decorator)
        end

        let(:branch_version) { instance_double("PactBroker::Versions::BranchVersion") }
        let(:parsed_branch_version) { double("parsed branch_version") }
        let(:branch_version_service) { class_double("PactBroker::Versions::Service").as_stubbed_const }
        let(:path) { "/branch-versions/#{uuid}" }
        let(:uuid) { "12345678" }
        let(:rack_headers) do
          {
            "HTTP_ACCEPT" => "application/hal+json"
          }
        end
        let(:decorator) do
          instance_double("PactBroker::Api::Decorators::BranchVersionDecorator",
            to_json: "response",
            from_json: parsed_branch_version
          )
        end

        describe "GET" do
          subject { get(path, nil, rack_headers) }

          it "attempts to find the BranchVersion" do
            expect(PactBroker::Versions::Service).to receive(:find_by_uuid).with(uuid)
            subject
          end

          context "when the branch_version does not exist" do
            let(:branch_version) { nil }

            it { is_expected.to be_a_404_response }
          end

          context "when the BranchVersion exists" do
            it "generates a JSON representation of the BranchVersion" do
              expect(PactBroker::Api::Decorators::BranchVersionDecorator).to receive(:new).with(branch_version)
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
