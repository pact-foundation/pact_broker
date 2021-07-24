require "webmock/rspec"

describe "get latest matrix badge with tags" do

  before do
    PactBroker.configuration.enable_public_badge_access = true
    PactBroker.configuration.badge_provider_mode = :proxy
    TestDataBuilder.new
      .create_consumer("consumer")
      .create_provider("provider")
      .create_consumer_version("1")
      .create_consumer_version_tag("prod")
      .create_pact
      .create_verification(provider_version: "4")
      .use_provider_version("4")
      .create_provider_version_tag("master")
  end

  let!(:http_request) do
    stub_request(:get, /http/).to_return(:status => 200, :body => "<svg/>")
  end

  let(:path) { "/matrix/provider/provider/latest/master/consumer/consumer/latest/prod/badge" }

  # In the full app, the .svg extension is turned into an Accept header
  # by ConvertFileExtensionToAcceptHeader

  subject { get(path, nil, {"HTTP_ACCEPT" => "image/svg+xml"}) }

  it "returns a 200 status" do
    expect(subject.status).to eq 200
  end

  it "returns an svg/xml response" do
    expect(subject.headers["Content-Type"]).to include("image/svg+xml")
  end

  it "returns an svg body" do
    expect(subject.body).to include "<svg/>"
  end

  context "when one of the pacticipants does not exist" do
    let(:path) { "/matrix/provider/provider/latest/master/consumer/consumer2/latest/prod/badge" }

    it "returns a 200 status as the badge content indicated the pact is not found" do
      expect(subject.status).to eq 200
      expect(subject.body).to include "not found"
    end
  end
end
