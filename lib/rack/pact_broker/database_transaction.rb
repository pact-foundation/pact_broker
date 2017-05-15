require 'pact_broker/version'
require 'sequel'

module Rack
  module PactBroker
    class DatabaseTransaction

      REQUEST_METHOD = "REQUEST_METHOD".freeze
      GET = "GET".freeze
      HEAD = "HEAD".freeze

      def initialize app, database_connection
        @app = app
        @database_connection = database_connection
      end

      def call env
        if env[REQUEST_METHOD] != GET && env[REQUEST_METHOD] != HEAD
          call_with_transaction env
        else
          call_without_transaction env
        end
      end

      def call_without_transaction env
        @app.call(env)
      end

      def call_with_transaction env
        response = nil
        @database_connection.transaction do
          response = @app.call(env)
          raise Sequel::Rollback if response.first == 500
        end
        response
      end
    end
  end
end
