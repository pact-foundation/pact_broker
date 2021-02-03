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
          ["PUT", "DELETE", "OPTIONS"]
        end

        def resource_exists?
          !!environment
        end

        def from_json
          @environment = create_or_update_environment
          response.body = to_json
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
          @environment ||= environment_service.find(environment_name)
        end

        def delete_resource
          environment_service.delete(environment_name)
          true
        end

        def environment_name
          identifier_from_path[:environment_name]
        end

        def create_or_update_environment
          if environment
            environment_service.update(environment_name, parsed_environment)
          else
            environment_service.create(environment_name, parsed_environment).tap do
              # Make it return a 201 by setting the Location header
              response.headers["Location"] = resource_url
            end
          end
        end
      end
    end
  end
end
