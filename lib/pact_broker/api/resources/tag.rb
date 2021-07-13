require "pact_broker/api/resources/base_resource"

module PactBroker
  module Api
    module Resources
      class Tag < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET","PUT","DELETE", "OPTIONS"]
        end

        def from_json
          unless tag
            @tag = tag_service.create identifier_from_path
            # Make it return a 201 by setting the Location header
            response.headers["Location"] = tag_url(base_url, tag)
          end
          create_deployed_version
          response.body = to_json
        end

        def resource_exists?
          !!tag
        end

        def to_json
          decorator_class(:tag_decorator).new(tag).to_json(decorator_options)
        end

        def tag
          @tag ||= tag_service.find identifier_from_path
        end

        def delete_resource
          tag_service.delete identifier_from_path
          true
        end

        def policy_name
          :'tags::tag'
        end

        def create_deployed_version
          if create_deployed_versions_for_tags?
            if (environment = environment_service.find_by_name(identifier_from_path[:tag_name]))
              deployed_version_service.find_or_create(deployed_version_service.next_uuid, tag.version, environment, nil)
            end
          end
        end

        # Come up with a cleaner way to abstract this for PF so it can be configured per tenant
        def create_deployed_versions_for_tags?
          PactBroker.configuration.create_deployed_versions_for_tags
        end
      end
    end
  end
end
