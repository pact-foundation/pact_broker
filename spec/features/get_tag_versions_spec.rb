describe "Get versions for Pacticipant Tag" do
  before do
    td.create_consumer("Boo")
      .create_version("1.2.3")
      .create_tag("prod")
      .and_return(:tag)
  end
  let(:tag) { PactBroker::Domain::Tag.first }
  let(:path) { PactBroker::Api::PactBrokerUrls.tag_versions_url(tag) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  subject { get(path, {}, headers) }

  it { is_expected.to be_a_hal_json_success_response }

  it "returns the tags versions" do
    expect(JSON.parse(subject.body).dig("_embedded", "versions").size).to eq 1
  end

  context "when the pacticipant does not exist" do 
    let(:path) { "pacticipants/Foo/tags/#{tag.name}/versions" }

    its(:status) { is_expected.to eq 404 }
  end

  context "when the tag does not exist" do
    let(:path) { "pacticipants/Boo/tags/feature_tag/versions" }

    its(:status) { is_expected.to eq 404 }
  end

  context "with pagination options" do
    subject { get(path, { "size" => "1", "page" => "1" }) }

    it "only returns the number of items specified in the size" do
      expect(JSON.parse(subject.body).dig("_embedded", "versions").size).to eq 1
    end

  end
end
