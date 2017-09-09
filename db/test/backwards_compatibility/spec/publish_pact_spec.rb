require 'rack/reverse_proxy'

code_version = ENV.fetch('PACT_BROKER_CODE_VERSION')
database_version = ENV.fetch('PACT_BROKER_DATABASE_VERSION')

describe "Code version #{code_version} running against database version #{database_version}" do
  describe "Publishing a pact" do

    before do
      unless ENV['OK']
        retries = 0
        begin
            get "/"
            ENV['OK'] = 'true'
        rescue Errno::ECONNREFUSED => error
          if retries < 10
            retries += 1
            sleep 1
            retry
          else
            raise error
          end
        end
      end
    end

    let(:pact_content) { load_fixture('foo-bar.json') }
    let(:path) { "/pacts/provider/Bar/consumer/Foo/version/1.2.3" }
    let(:response_body_json) { JSON.parse(subject.body) }

    let(:app) do
      Rack::ReverseProxy.new do
        reverse_proxy_options preserve_host: true
        reverse_proxy '/', "http://localhost:#{ENV.fetch('PORT')}/"
      end
    end

    subject { put path, pact_content, {'CONTENT_TYPE' => 'application/json' }; last_response  }


    it "returns a success status" do
      expect(subject.status.to_s).to match /20\d/
    end

    it "returns the pact in the body" do
      expect(response_body_json).to include JSON.parse(pact_content)
    end
  end
end
