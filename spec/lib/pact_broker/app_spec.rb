require 'pact_broker/app'

module PactBroker
  describe App do

    class TestApp < PactBroker::App

      def configure_database_connection
        # do nothing
      end

      def migrate_database
        # do nothing
      end

    end

    let(:app) do
      TestApp.new do | configuration |
        configuration.database_connection = PactBroker::DB.connection
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

    describe "authenticate_with_basic_auth" do
      before do
        PactBroker.configuration.authenticate_with_basic_auth do | username, password, resource |
          resource.user = Object.new
          username == 'username' && password == 'password'
        end
      end

      context "with incorrect username or password" do
        it "returns a 401" do
          basic_authorize 'foo', 'password'
          get "/"
          expect(last_response.status).to eq 401
        end
      end

      context "with matching username and password" do
        it "returns a 200" do
          basic_authorize 'username', 'password'
          get "/"
          expect(last_response.status).to eq 200
        end
      end
    end

    describe "authorize" do
      PactBroker.configuration.authorize do | resource |
        resource.request.get?
      end

      context "with an an authorized request" do
        it "returns a 200" do
          get "/"
          expect(last_response.status).to eq 200
        end
      end

      context "with an an aunauthorized request" do
        it "returns a 405" do
          put "/"
          expect(last_response.status).to eq 405
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
