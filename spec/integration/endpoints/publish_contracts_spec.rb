RSpec.describe "publishing a pact using the all in one endpoint" do
  let(:request_body_hash) do
    {
      :pacticipantName => "Foo",
      :pacticipantVersionNumber => "1",
      :branch => "main",
      :tags => ["a", "b"],
      :buildUrl => "http://ci/builds/1234",
      :contracts => [
        {
          :consumerName => "Foo",
          :providerName => "Bar",
          :specification => "pact",
          :contentType => "application/json",
          :content => encoded_contract,
          :onConflict => "overwrite",
        }
      ]
    }
  end
  let(:rack_headers) { { "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/hal+json" } }
  let(:encoded_contract) { Base64.strict_encode64(contract) }
  let(:path) { "/contracts/publish" }

  subject { post(path, request_body_hash.to_json, rack_headers) }

  context "with invalid UTF-8 in the request body" do
    let(:contract) { "{\"key\": \"ABCDEFG\x8FDEF\" }" }

    its(:status) { is_expected.to eq 400 }
    its(:body) { is_expected.to include("non UTF-8 character") }
  end
end
