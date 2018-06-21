require 'pact_broker/api/resources/base_resource'
require 'pact_broker/api/decorators/label_decorator'

module PactBroker
  module Api
    module Resources
      class Label < BaseResource

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def content_types_accepted
          [["application/json", :from_json]]
        end

        def allowed_methods
          ["GET", "PUT", "DELETE", "OPTIONS"]
        end

        def from_json
          unless label
            @label = label_service.create identifier_from_path
            # Make it return a 201 by setting the Location header
            response.headers["Location"] = label_url(label, base_url)
          end
          response.body = to_json
        end

        def resource_exists?
          label
        end

        def to_json
          PactBroker::Api::Decorators::LabelDecorator.new(label).to_json(user_options: { base_url: base_url })
        end

        def label
          @label ||= label_service.find identifier_from_path
        end

        def delete_resource
          label_service.delete identifier_from_path
          true
        end

      end
    end

  end
end
