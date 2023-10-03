require "pact_broker/api/resources/base_resource"
require "pact_broker/api/resources/pagination_methods"
require "pact_broker/api/resources/filter_methods"

module PactBroker
  module Api
    module Resources
      class PacticipantBranches < BaseResource
        include PaginationMethods
        include FilterMethods

        def content_types_provided
          [["application/hal+json", :to_json]]
        end

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def resource_exists?
          !!pacticipant
        end

        def to_json
          decorator_class(:pacticipant_branches_decorator).new(branches).to_json(**decorator_options(pacticipant: pacticipant))
        end

        def policy_name
          :'versions::branches'
        end

        private

        def branches
          @branches ||= branch_service.find_all_branches_for_pacticipant(
                          pacticipant,
                          filter_options,
                          default_pagination_options.merge(pagination_options),
                          eager_load_associations
                        )
        end

        def eager_load_associations
          decorator_class(:pacticipant_branches_decorator).eager_load_associations
        end
      end
    end
  end
end
