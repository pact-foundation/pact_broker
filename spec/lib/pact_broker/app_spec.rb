require 'pact_broker/app'

module PactBroker
  describe App do

    before do
      allow(PactBroker::DB).to receive(:run_migrations)
    end

    class TestApp < PactBroker::App
      def configure_database_connection
        # do nothing so we don't screw up our test connection
      end
    end

    let(:app) do
      TestApp.new do | configuration |
        configuration.database_connection = PactBroker::DB.connection
      end
    end

    describe "on start up" do
      it "fails any retrying triggered webhooks left over when the app shut down" do
        expect(PactBroker::Webhooks::Service).to receive(:fail_retrying_triggered_webhooks)
        app
      end
    end

    it "adds the X-Pact-Broker-Version header" do
      get "/"
      expect(last_response.headers['X-Pact-Broker-Version']).to match /\d/
    end

    class Middleware

      def initialize app
        @app = app
      end

      def call env
        self.class.calls << env
        @app.call(env)
      end

      def self.calls
        @calls ||= []
      end
    end

    it "acts like a ::Rack::Builder" do
      app.use Middleware
      expect { get "/" }.to change { Middleware.calls.count }.by(1)
    end

    describe "before_resource and after_resource" do
      CALLBACKS = []
      before do
        PactBroker.configuration.before_resource { | resource | CALLBACKS << "before" }
        PactBroker.configuration.after_resource { | resource | CALLBACKS << "after" }
      end

      it "executes the callbacks" do
        get "/"
        expect(CALLBACKS).to eq ["before", "after"]
      end
    end

    describe "authenticate" do
      before do
        PactBroker.configuration.authenticate do | resource, authorization_header, options |
          authorization_header == 'letmein'
        end
      end

      context "with an invalid Authorization header" do
        it "returns a 401" do
          get "/", {}, {'HTTP_AUTHORIZATION' => 'wrong'}
          expect(last_response.status).to eq 401
        end
      end

      context "with valid Authorization header" do
        it "returns a 200" do
          get "/", {}, {'HTTP_AUTHORIZATION' => 'letmein'}
          expect(last_response.status).to eq 200
        end
      end
    end

    describe "authenticate_with_basic_auth" do
      before do
        PactBroker.configuration.authenticate_with_basic_auth do | resource, username, password, options |
          username == 'username' && password == 'password'
        end
      end

      context "with a request for the API with incorrect username or password" do
        it "returns a 401" do
          basic_authorize 'foo', 'password'
          get "/"
          expect(last_response.status).to eq 401
        end
      end

      context "with a request for the UI with incorrect username or password" do
        it "returns a 401" do
          basic_authorize 'foo', 'password'
          get "/", nil, {'HTTP_ACCEPT' => 'text/html'}
          expect(last_response.status).to eq 401
        end
      end

      context "with a request for diagnostics with incorrect username or password" do
        it "returns a 401" do
          basic_authorize 'foo', 'password'
          get "/diagnostic/status/heartbeat"
          expect(last_response.status).to eq 401
        end
      end

      context "with a request for the API with correct username and password" do
        it "returns a 200" do
          basic_authorize 'username', 'password'
          get "/"
          expect(last_response.status).to eq 200
        end
      end

      context "with a request for the UI with correct username or password" do
        it "returns a 200" do
          basic_authorize 'username', 'password'
          get "/", nil, {'HTTP_ACCEPT' => 'text/html'}
          expect(last_response.status).to eq 200
        end
      end

      context "with a request for diagnostics with correct username or password" do
        it "returns a 200" do
          basic_authorize 'username', 'password'
          get "/diagnostic/status/heartbeat"
          expect(last_response.status).to eq 200
        end
      end
    end

    describe "authorize" do
      before do
        PactBroker.configuration.authorize do | resource, options |
          resource.request.headers['Role'] == 'important'
        end
      end

      context "with a request for the API with an authorized request" do
        it "returns a 200" do
          get "/", nil, {'HTTP_ROLE' => 'important'}
          expect(last_response.status).to eq 200
        end
      end

      context "with a request for the UI with an authorized request" do
        it "returns a 200" do
          get "/", nil, {'HTTP_ACCEPT' => 'text/html', 'HTTP_ROLE' => 'important'}
          expect(last_response.status).to eq 200
        end
      end

      context "with a request for diagnostics with an authorized request" do
        it "returns a 200" do
          get "/diagnostic/status/heartbeat", nil, {'HTTP_ROLE' => 'important'}
          expect(last_response.status).to eq 200
        end
      end

      context "with a request for the API with an unauthorized request" do
        it "returns a 403" do
          get "/"
          expect(last_response.status).to eq 403
        end
      end

      context "with a request for the UI with an unauthorized request" do
        it "returns a 200 because there's no point doing authorization on the UI at the moment" do
          get "/", nil, {'HTTP_ACCEPT' => 'text/html'}
          expect(last_response.status).to eq 200
        end
      end

      context "with a request for diagnostics with an unauthorized request" do
        it "returns a 403" do
          get "/diagnostic/status/heartbeat"
          expect(last_response.status).to eq 403
        end
      end
    end

    describe "transactions", no_db_clean: true do
      let(:pact_content) { load_fixture('a_consumer-a_provider.json') }
      let(:path) { "/pacts/provider/A%20Provider/consumer/A%20Consumer/versions/1.2.3" }
      let(:response_body_json) { JSON.parse(subject.body) }

      before do
        PactBroker::Database.truncate
        allow_any_instance_of(PactBroker::Pacts::Repository).to receive(:create).and_raise("an error")
      end

      after do
        PactBroker::Database.truncate
      end

      subject { put path, pact_content, {'CONTENT_TYPE' => 'application/json' }; last_response  }

      it "wraps the API with a database transaction" do
        expect { subject }.to_not change { PactBroker::Domain::Pacticipant.count }
      end
    end
  end
end
