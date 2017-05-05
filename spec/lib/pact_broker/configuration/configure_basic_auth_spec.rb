require 'pact_broker/configuration/configure_basic_auth'
require 'pact_broker/app'

module PactBroker
  class Configuration
    describe ConfigurableBasicAuth do

      let(:target_app) { ->(env){  [200, {}, ["hello"]] } }
      let(:app) do
        auth_app = ConfigurableBasicAuth.new(target_app)
        auth_app.protect(username: 'username', password: 'password') do | env |
          env['PATH_INFO'] == '/foo'
        end
        auth_app
      end

      context "when not authorized" do
        it "does not allow requests" do
          get "/foo"
          expect(last_response.status).to eq 401
        end
      end

      context "when authorized" do
        before { basic_authorize 'username', 'password' }
        it "allows requests" do
          get "/foo"
          expect(last_response.status).to eq 200
        end
      end
    end

    describe ConfigureBasicAuth do
      def read_request_to_ui
        get "/"
        last_response
      end

      def read_request_to_api
        get "/pacts/latest"
        last_response
      end

      def write_request_to_api
        put "/pacts/provider/foo/consumer/bar/version/1.2.3", '{}', {'Content-Type' => 'application/json'}
        last_response
      end

      def read_request_to_diagnostic
        get "/diagnostic/status/heartbeat"
        last_response
      end

      def authorize_request
        basic_authorize 'username', 'password'
      end


      before do
        PactBroker.reset_configuration
      end

      describe "with no basic_auth" do
        let(:app) do
          app = PactBroker::App.new do | config |
            config.database_connection = PactBroker::DB.connection
          end
        end

        context "when not authorized" do
          it "allows GET requests to the UI" do
            expect(read_request_to_ui.status).to_not eq 401
          end

          it "allows GET requests to the API" do
            expect(read_request_to_api.status).to_not eq 401
          end

          it "allows non GET requests to the API" do
            expect(write_request_to_api.status).to_not eq 401
          end

          it "allows GET requests to the diagnostics app" do
            expect(read_request_to_diagnostic.status).to_not eq 401
          end
        end
      end

      describe "with basic_auth for :all" do
        let(:app) do
          app = PactBroker::App.new do | config |
            config.database_connection = PactBroker::DB.connection
            config.protect_with_basic_auth :all, {username: 'username', password: 'password'}
          end
        end

        context "when authorized" do
          before do
            authorize_request
          end

          it "allows GET requests to the UI" do
            expect(read_request_to_ui.status).to_not eq 401
          end

          it "allows GET requests to the API" do
            expect(read_request_to_api.status).to_not eq 401
          end

          it "allows non GET requests to the API" do
            expect(write_request_to_api.status).to_not eq 401
          end

          it "allows GET requests to the diagnostics app" do
            expect(read_request_to_diagnostic.status).to_not eq 401
          end
        end

        context "when not authorized" do
          it "does not allow GET requests to the UI" do
            expect(read_request_to_ui.status).to eq 401
          end

          it "does not allow GET requests the API" do
            expect(read_request_to_api.status).to eq 401
          end

          it "does not allow non GET requests the API" do
            expect(write_request_to_api.status).to eq 401
          end

          it "does not allow GET requests to the diagnostics app" do
            expect(read_request_to_diagnostic.status).to eq 401
          end
        end
      end

      describe "with basic_auth for :app_write" do

        let(:app) do
          app = PactBroker::App.new do | config |
            config.database_connection = PactBroker::DB.connection
            config.protect_with_basic_auth :app_write, {username: 'username', password: 'password'}
          end
        end

        context "when authorized" do
          before do
            authorize_request
          end

          it "allows GET requests to the diagnostics app" do
            expect(read_request_to_diagnostic.status).to_not eq 401
          end

          it "allows GET requests to the app_write app" do
            expect(read_request_to_diagnostic.status).to_not eq 401
          end
        end

        context "when not authorized" do

          it "allows GET requests to the UI" do
            expect(read_request_to_ui.status).to_not eq 401
          end

          it "allows GET requests the API" do
            expect(read_request_to_api.status).to_not eq 401
          end

          it "does not allow non GET requests the API" do
            expect(write_request_to_api.status).to eq 401
          end

          it "allows GET requests to the diagnostics app" do
            expect(read_request_to_diagnostic.status).to_not eq 401
          end
        end
      end
    end
  end
end
