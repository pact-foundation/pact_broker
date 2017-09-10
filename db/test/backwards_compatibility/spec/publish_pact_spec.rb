require 'rack/reverse_proxy'
require 'securerandom'

CODE_VERSION = ENV.fetch('PACT_BROKER_CODE_VERSION')
DATABASE_VERSION = ENV.fetch('PACT_BROKER_DATABASE_VERSION')
CONSUMER_VERSION = CODE_VERSION == 'head' ? '100.100.100' : CODE_VERSION
TAG = SecureRandom.hex

describe "Code version #{CODE_VERSION} running against database version #{DATABASE_VERSION}" do

  before do
    wait_for_server_to_start
  end

  let(:path) { "/pacts/provider/Bar/consumer/Foo/version/#{CONSUMER_VERSION}" }
  let(:response_body_json) { JSON.parse(subject.body) }
  let(:pact_content) do
    pact = load_json_fixture('foo-bar.json')
    pact['interactions'][0]['providerState'] = "the code version is #{CODE_VERSION}"
    pact.to_json
  end

  let(:app) do
    Rack::ReverseProxy.new do
      reverse_proxy_options preserve_host: true
      reverse_proxy '/', "http://localhost:#{ENV.fetch('PORT')}/"
    end
  end

  describe "tagging a consumer version" do
    let(:path) { "/pacticipants/Foo/versions/#{CONSUMER_VERSION}/tags/#{TAG}"}
    subject { put path, nil, {'CONTENT_TYPE' => 'application/json' }; last_response  }

    it "returns a success status" do
      expect(subject.status.to_s).to match /20\d/
    end
  end

  describe "publishing a pact" do
    subject { put path, pact_content, {'CONTENT_TYPE' => 'application/json' }; last_response  }

    it "returns a success status" do
      expect(subject.status.to_s).to match /20\d/
    end
  end

  describe "retrieving a pact" do
    subject { get path; last_response  }

    it "returns the pact in the body" do
      expect(response_body_json).to include JSON.parse(pact_content)
    end
  end

  describe "retrieving the latest tagged pact" do
    let(:path) { "/pacts/provider/Bar/consumer/Foo/latest" }
    subject { get path; last_response  }

    it "returns the latest pact" do
      expect(subject.headers['X-Pact-Consumer-Version']).to eq '100.100.100'
    end
  end

  describe "retrieving the latest tagged pact" do
    let(:path) { "/pacts/provider/Bar/consumer/Foo/latest/#{TAG}" }
    subject { get path; last_response  }

    it "returns the pact in the body" do
      expect(response_body_json).to include JSON.parse(pact_content)
    end
  end
end
