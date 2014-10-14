require 'pact_broker/api/resources/base_resource'

module PactBroker
  module Api
    module Resources

      class Pacts < BaseResource

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["POST"]
        end

        def malformed_request?
          invalid_consumer_version? || missing_pacticipant_names?
        end

        def post_is_create?
          true
        end

        def create_path

        end

        def from_json

        end

        def missing_pacticipant_names?

          false
        end

        def invalid_consumer_version?
          missing_consumer_version_number? || invalid_version_number?
        end

        def missing_consumer_version_number?
          if consumer_version_number.nil?
            set_json_error_message("Please specify the consumer version number by setting the X-Pact-Consumer-Version header.")
          end
        end

        def invalid_version_number?
          begin
            Versionomy.parse(consumer_version_number)
            false
          rescue Versionomy::Errors::ParseError => e
            set_json_error_message "X-Pact-Consumer-Version '#{consumer_version_number}' is not recognised as a standard semantic version. eg. 1.3.0 or 2.0.4.rc1"
            true
          end
        end

        def consumer_version_number
          request.headers['X-Pact-Consumer-Version']
        end

        def pact

        end

      end
    end

  end
end