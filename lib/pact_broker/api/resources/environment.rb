require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/resources/environment'

module PactBroker
  module Api
    module Resources
      class Environment < BaseResource
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
          !!environment
        end

        def from_json
          if environment
            @environment = update_environment
            response.body = to_json
          else
            response.code = 404
          end
        end

        def policy_name
          :'deployments::environment'
        end

        def to_json
          decorator_class(:environment_decorator).new(environment).to_json(decorator_options)
        end

        def parsed_environment
          @parsed_environment ||= decorator_class(:environment_decorator).new(PactBroker::Deployments::Environment.new).from_json(request_body)
        end

        def environment
          @environment ||= environment_service.find(uuid)
        end

        def delete_resource
          environment_service.delete(uuid)
          true
        end

        def uuid
          identifier_from_path[:environment_uuid]
        end

        def update_environment
          environment_service.update(uuid, parsed_environment)
        end
      end
    end
  end
end
