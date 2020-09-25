RSpec.describe "can i deploy badge" do
  before do
    td.create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
      .create_consumer_version_tag("main")
  end

  subject { get("/pacticipants/Foo/latest-version/main/can-i-deploy/to/prod/badge", nil, { 'HTTP_ACCEPT' => 'image/svg+xml'}) }

  it "returns a redirect response" do
    expect(subject.status).to eq 307
    expect(subject.headers['Location']).to start_with "https://img.shields.io/badge"
  end
end
