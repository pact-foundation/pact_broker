require "pact_broker/api/resources/can_i_deploy_pacticipant_version_by_tag_to_tag"
require "pact_broker/matrix/service"

module PactBroker
  module Api
    module Resources
      describe CanIDeployPacticipantVersionByTagToTag do
        include_context "stubbed services"

        before do
          allow(PactBroker::Matrix::Service).to receive(:can_i_deploy).and_return([])
          allow(pacticipant_service).to receive(:find_pacticipant_by_name).and_return(pacticipant)
          allow(PactBroker::Api::Decorators::MatrixDecorator).to receive(:new).and_return(decorator)
        end

        let(:pacticipant) { double("pacticipant") }
        let(:version) { double("version") }
        let(:json_response_body) { JSON.parse(subject.body, symbolize_names: true) }
        let(:decorator) { double("decorator", to_json: "response_body") }
        let(:selectors) { double("selectors") }
        let(:options) { double("options") }

        subject { get(path, nil, "Content-Type" => "application/hal+json") }

        context "with tags" do
          before do
            allow(version_service).to receive(:find_by_pacticipant_name_and_latest_tag).and_return(version)
          end

          let(:path) { "/pacticipants/Foo/latest-version/main/can-i-deploy/to/prod" }

          it "looks up the by tag" do
            expect(version_service).to receive(:find_by_pacticipant_name_and_latest_tag).with("Foo", "main")
            subject
          end

          it { is_expected.to be_a_hal_json_success_response }

          context "when the version does not exist" do
            let(:version) { nil }

            its(:status) { is_expected.to eq 404 }
          end
        end
      end
    end
  end
end
