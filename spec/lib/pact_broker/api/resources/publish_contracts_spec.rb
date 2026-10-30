require "pact_broker/api/resources/publish_contracts"

module PactBroker
  module Api
    module Resources
      describe PublishContracts do
        let(:path) { "/contracts/publish" }
        subject { post(path, request_body, rack_headers ) }

        let(:request_body) { "" }

        context "with the wrong content type" do
          let(:request_body) { "foo" }
          let(:rack_headers) do
            {
              "CONTENT_TYPE" => "text/plain"
            }
          end

          its(:status) { is_expected.to eq 415 }
        end

        context "with the wrong accept type" do
          let(:rack_headers) do
            {
              "CONTENT_TYPE" => "text/plain",
              "HTTP_ACCEPT" => "text/plain"
            }
          end

          its(:status) { is_expected.to eq 406 }
        end

        context "with a valid request" do
          let(:request_body) do
            {
              pacticipantName: "Foo",
              pacticipantVersionNumber: "1",
              contracts: [
                {
                  consumerName: "Foo",
                  providerName: "Bar",
                  specification: "pact",
                  contentType: "application/json",
                  content: Base64.strict_encode64(contract)
                }
              ]
            }.to_json
          end
          let(:contract) { { consumer: { name: "Foo" }, provider: { name: "Bar" }, interactions: [] }.to_json }
          let(:rack_headers) do
            {
              "CONTENT_TYPE" => "application/json",
              "HTTP_ACCEPT" => "application/hal+json"
            }
          end

          its(:status) { is_expected.to eq 200 }

          context "when pact equality is based on the content that affects verification results" do
            before do
              PactBroker.configuration.base_equality_only_on_content_that_affects_verification_results = true
            end

            it "stores the pact with the sha generated from the contract content" do
              subject
              expect(PactBroker::Pacts::PactVersion.last.sha).to eq PactBroker::Pacts::GenerateSha.call(contract)
            end
          end

          describe "params" do
            let(:request) do
              Webmachine::Request.new("POST", URI("http://example.org/contracts/publish"), Webmachine::Headers["Content-Type" => "application/json"], request_body).tap do | request |
                # Set by the router in a real request
                request.path_info = { application_context: PactBroker::ApplicationContext.default_application_context }
              end
            end
            let(:resource) { PublishContracts.new(request, Webmachine::Response.new) }
            let(:params) { resource.send(:params) }

            it "decodes and parses the contract content" do
              expect(params["contracts"].first).to include("decodedContent" => contract, "decodedParsedContent" => JSON.parse(contract))
            end

            it "only decodes and parses each contract once, however many times it is called" do
              expect(resource.send(:params)["contracts"].first["decodedParsedContent"]).to be params["contracts"].first["decodedParsedContent"]
            end
          end
        end
      end
    end
  end
end
