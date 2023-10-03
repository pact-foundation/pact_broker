require "pact_broker/api/decorators/base_decorator"
require "pact_broker/api/decorators/timestamps"
require "pact_broker/api/decorators/pagination_links"
require "pact_broker/api/decorators/branch_decorator"

module PactBroker
  module Api
    module Decorators
      class PacticipantBranchesDecorator < BaseDecorator
        collection :entries, as: :branches, embedded: true, :extend => PactBroker::Api::Decorators::BranchDecorator

        link :self do | user_options |
          {
            title: "#{user_options.fetch(:pacticipant).name} branches",
            href: user_options.fetch(:request_url)
          }
        end

        links "pb:branches" do | user_options |
          represented.collect do | branch |
            {
              name: branch.name,
              href: branch_url(branch, user_options.fetch(:base_url))
            }
          end
        end

        include PaginationLinks
      end
    end
  end
end
