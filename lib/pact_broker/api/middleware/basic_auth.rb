require "rack"

module PactBroker
  module Api
    module Middleware
      class BasicAuth
        def initialize(app, write_credentials, read_credentials, policy)
          @app = app
          @write_credentials = write_credentials
          @read_credentials = read_credentials
          @app_with_write_auth = build_app_with_write_auth
          @app_with_read_auth = build_app_with_read_auth
          @policy = policy
        end

        def call(env)
          if policy.public_access_allowed?(env)
            app.call(env)
          elsif policy.read_access_allowed?(env)
            app_with_read_auth.call(env)
          else
            app_with_write_auth.call(env)
          end
        end

        protected

        def write_credentials_match(*credentials)
          credentials == write_credentials
        end

        def read_credentials_match(*credentials)
          is_set(read_credentials[0]) && credentials == read_credentials
        end

        private

        attr_reader :app, :app_with_read_auth, :app_with_write_auth, :write_credentials, :read_credentials, :policy

        def build_app_with_write_auth
          this = self
          Rack::Auth::Basic.new(app, "Restricted area") do |username, password|
            this.write_credentials_match(username, password)
          end
        end

        def build_app_with_read_auth
          this = self
          Rack::Auth::Basic.new(app, "Restricted area") do |username, password|
            this.write_credentials_match(username, password) || this.read_credentials_match(username, password)
          end
        end

        def is_set(string)
          string && string.strip.size > 0
        end
      end
    end
  end
end
