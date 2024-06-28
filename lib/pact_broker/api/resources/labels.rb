require "pact_broker/api/resources/base_resource"
require "pact_broker/api/decorators/labels_decorator"
require "pact_broker/api/resources/pagination_methods"

module PactBroker
  module Api
    module Resources
      class Labels < BaseResource
        include PaginationMethods

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def policy_name
          :'labels::labels'
        end

        def to_json
          decorator_class(:labels_decorator).new(labels).to_json(
            **decorator_options(
              hide_label_decorator_links: true,
            )
          )
        end

        def labels
          label_service.get_all_unique_labels(pagination_options)
        end
      end
    end
  end
end
