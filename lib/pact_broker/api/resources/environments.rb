require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/resources/environment'
require 'pact_broker/api/contracts/environment_schema'

module PactBroker
  module Api
    module Resources
      class Environments < BaseResource
        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "POST", "OPTIONS"]
        end

        def resource_exists?
          true
        end

        def post_is_create?
          true
        end

        def malformed_request?
          if request.post?
            invalid_json? || validation_errors_for_schema?(schema, params.merge(uuid: uuid))
          else
            false
          end
        end

        def create_path
          environment_url(OpenStruct.new(uuid: uuid), base_url)
        end

        def from_json
          response.body = decorator_class(:environment_decorator).new(create_environment).to_json(decorator_options)
        end

        def policy_name
          :'deployments::environments'
        end

        def to_json
          decorator_class(:environments_decorator).new(environments).to_json(decorator_options)
        end

        def parsed_environment
          @parsed_environment ||= decorator_class(:environment_decorator).new(PactBroker::Deployments::Environment.new).from_json(request_body)
        end

        def create_environment
          environment_service.create(uuid, parsed_environment)
        end

        def uuid
          @uuid ||= environment_service.next_uuid
        end

        def environments
          @environments ||= if request.query['name']
            [environment_service.find_by_name(request.query['name'])]
          else
            environment_service.find_all
                            end
        end

        def schema
          PactBroker::Api::Contracts::EnvironmentSchema
        end
      end
    end
  end
end
