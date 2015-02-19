require 'webmachine'
require 'pact_broker/db'
require 'pact_broker/logging'

module PactBroker
  module Diagnostic
    module Resources
      class Dependencies < Webmachine::Resource

        include Logging

        def initialize
          @return_status = 200
        end

        def allowed_methods
          ["GET"]
        end

        def content_types_provided
          [["application/json+hal", :to_json]]
        end

        def to_json
          response.body = {
            "database" => database_connectivity_status,
            "_links" => {
              "self" => {
                "href" => request.uri.to_s
              }
            }
          }.to_json

          @return_status
        end

        private

        def database_connectivity_status
          begin
            valid = valid_database_connection?
            @return_status = 500 unless valid
            {
              "ok" => valid
            }
          rescue => e
            logger.error "#{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
            @return_status = 500
            {
              "ok" => false,
              "error" => {
                "message" => "#{e.class} - #{e.message}"
              }
            }
          end
        end

        def valid_database_connection?
          connection = PactBroker::DB.connection
          connection.synchronize do |synchronized_connection|
            connection.valid_connection? synchronized_connection
          end
        end

      end
    end
  end
end
