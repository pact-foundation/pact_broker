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
      end
    end
  end
end
