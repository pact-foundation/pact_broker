require 'pact_broker/api/resources/version'

module PactBroker
  module Api
    module Resources
      describe Version do
        include_context "stubbed services"

        before do
          allow(version_service).to receive(:find_by_pacticipant_name_and_number).and_return(saved_version)
        end
        let(:decorator) { double('decorator', to_json: 'response_json', from_json: parsed_version) }
        let(:parsed_version) { double('parsed_version') }
        let(:existing_version) { double('existing_version') }
        let(:saved_version) { double('saved_version') }

        describe "PUT" do
          before do
            allow_any_instance_of(described_class).to receive_message_chain(:decorator_class, :new).and_return(decorator)
            allow(decorator).to receive(:from_json).and_return(parsed_version)
            allow(version_service).to receive(:find_by_pacticipant_name_and_number).and_return(existing_version)
            allow(version_service).to receive(:create_or_update).and_return(saved_version)
          end
          let(:request_body) { { some: 'body'}.to_json }
          let(:rack_env) do
            {
              "CONTENT_TYPE" => "application/json",
              "HTTP_ACCEPT" => "application/hal+json"
            }
          end

          subject { put("/pacticipants/Foo/versions/1234", request_body, rack_env) }

          context "when the version already exists" do
            it "returns a 200" do
              expect(subject.status).to eq 200
            end
          end

          context "when the version does not exist" do
            let(:existing_version) { nil }

            it "returns a 201" do
              expect(subject.status).to eq 201
            end
          end
        end
      end
    end
  end
end
