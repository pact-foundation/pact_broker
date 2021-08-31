require "pact_broker/diagnostic/resources/base_resource"
require "pact_broker/db"
require "pact_broker/logging"

module PactBroker
  module Diagnostic
    module Resources
      class Dependencies < BaseResource

        include Logging

        def initialize
          @return_status = 200
        end

        def allowed_methods
          ["GET"]
        end

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def to_json
          ok, report = database_connectivity_status
          response.body = {
            "database" => report,
            "_links" => {
              "self" => {
                "href" => base_url + "/diagnostic/status/dependencies"
              }
            }
          }.to_json

          ok ? 200 : 500
        end

        private

        def database_connectivity_status
          begin
            valid = valid_database_connection?
            return valid, { "ok" => valid }
          rescue => e
            logger.error "#{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
            report = {
              "ok" => false,
              "error" => {
                "message" => "#{e.class} - #{e.message}"
              }
            }
            return false, report
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
