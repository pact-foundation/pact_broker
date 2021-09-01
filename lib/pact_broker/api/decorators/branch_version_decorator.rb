require "pact_broker/api/decorators/base_decorator"
require "pact_broker/api/decorators/timestamps"

module PactBroker
  module Api
    module Decorators
      class BranchVersionDecorator < BaseDecorator

        link :self do | user_options |
          {
            title: "Branch version",
            href: branch_version_url(represented, user_options.fetch(:base_url))
          }
        end

        include Timestamps
      end
    end
  end
end
