require 'pact_broker/services'
require 'pact_broker/api/decorators/version_decorator'
require 'pact_broker/api/resources/base_resource'

module PactBroker
  module Api
    module Resources
      class Version < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "PUT", "DELETE", "OPTIONS"]
        end

        def resource_exists?
          !!version
        end

        def from_json
          response_code = version ? 200 : 201
          parsed_version = Decorators::VersionDecorator.new(OpenStruct.new).from_json(request_body)
          @version = version_service.create_or_overwrite(pacticipant_name, pacticipant_version_number, parsed_version)
          response.body = to_json
          response_code
        end

        def to_json
          decorator_class(:version_decorator).new(version).to_json(decorator_options(environments: environments))
        end

        def delete_resource
          version_service.delete(version)
          true
        end

        def policy_name
          :'versions::version'
        end

        private

        def environments
          @environments ||= environment_service.find_for_pacticipant(version.pacticipant)
        end

        def version
          @version ||= version_service.find_by_pacticipant_name_and_number(identifier_from_path)
        end
      end
    end
  end
end
