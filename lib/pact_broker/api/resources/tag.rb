require 'pact_broker/api/resources/base_resource'

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
          response.body = to_json
        end

        def resource_exists?
          !!tag
        end

        def to_json
          PactBroker::Api::Decorators::TagDecorator.new(tag).to_json(decorator_options)
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
      end
    end
  end
end
