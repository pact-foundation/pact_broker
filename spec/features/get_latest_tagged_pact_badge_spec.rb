require 'webmock/rspec'

describe "get latest tagged pact badge" do

  before do
    PactBroker.configuration.enable_public_badge_access = true
    PactBroker.configuration.shields_io_base_url = nil
    TestDataBuilder.new
      .create_consumer('consumer')
      .create_provider('provider')
      .create_consumer_version('1.0.0')
      .create_consumer_version_tag('prod')
      .create_pact
      .create_verification(success: true)
      .create_consumer_version('1.2.3')
      .create_pact
      .create_verification(success: false)
  end

  let(:path) { "/pacts/provider/provider/consumer/consumer/latest/prod/badge" }

  # In the full app, the .svg extension is turned into an Accept header
  # by ConvertFileExtensionToAcceptHeader

  subject { get path, nil, {'HTTP_ACCEPT' => "image/svg+xml"}; last_response  }

  it "returns a 200 status" do
    expect(subject.status).to eq 200
  end

  it "returns an svg/xml response" do
    expect(subject.headers['Content-Type']).to include("image/svg+xml")
  end

  it "returns an svg body" do
    expect(subject.body).to include ">verified<"
  end
end
