require 'webmock/rspec'

describe "get pact badge" do

  before do
    TestDataBuilder.new
      .create_consumer('consumer')
      .create_provider('provider')
      .create_consumer_version('1.2.3')
      .create_pact
      .create_verification
  end

  let!(:http_request) do
    stub_request(:get, /http/).to_return(:status => 200, :body => "<svg/>")
  end

  let(:path) { "/pacts/provider/provider/consumer/consumer/latest/badge" }

  # In the full app, the .svg extension is turned into an Accept header
  # by ConvertFileExtensionToAcceptHeader

  subject { get path, nil, {'HTTP_ACCEPT' => "image/svg+xml"}; last_response  }

  it "returns an svg/xml response" do
    expect(subject.headers['Content-Type']).to include("image/svg+xml")
  end

  it "returns an svg body" do
    expect(subject.body).to include "<svg/>"
  end
end
