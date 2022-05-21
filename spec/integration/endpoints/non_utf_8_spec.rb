RSpec.describe "a request to publish a pact with non-utf-8 chars" do

  subject { put("/pacts/provider/Bar/consumer/Foo/version/2", pact_content, { "CONTENT_TYPE" => "application/json"}) }

  context "with less than 100 chars preceding the invalid char" do
    let(:pact_content) do
      "ABCDEFG\x8FDEF"
    end

    its(:status) { is_expected.to eq 400 }

    it "returns an error indicating where the non UTF-8 character is" do
      expect(JSON.parse(subject.body)).to eq("error" => "Request body has a non UTF-8 character at char 8 and cannot be parsed as JSON. Fragment preceding invalid character is: 'ABCDEFG'")
    end
  end

  context "with more than 100 chars preceding the invalid char" do
    let(:pact_content) do
      "12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890\x8FDEF"
    end

    it "truncates the fragement included in the error message" do
      expect(JSON.parse(subject.body)).to eq("error" => "Request body has a non UTF-8 character at char 101 and cannot be parsed as JSON. Fragment preceding invalid character is: '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890'")
    end
  end
end

RSpec.describe "a request to publish a pact with invalid JSON" do
  let(:pact_content) do
    "{"
  end

  subject { put("/pacts/provider/Bar/consumer/Foo/version/2", pact_content, { "CONTENT_TYPE" => "application/json"}) }

  its(:status) { is_expected.to eq 400 }

  it "returns an error message" do
    expect(JSON.parse(subject.body)).to eq("error" => "JSON::ParserError - 859: unexpected token at '{'")
  end
end
