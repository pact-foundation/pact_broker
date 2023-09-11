require "pact_broker/api/decorators/base_decorator"
require "pact_broker/api/decorators/timestamps"

module PactBroker
  module Api
    module Decorators
      class BranchDecorator < BaseDecorator

        property :name

        link :self do | user_options |
          {
            title: "Branch",
            href: branch_url(represented, user_options.fetch(:base_url))
          }
        end

        link "pb:latest-version" do | user_options |
          {
            title: "Latest version for branch",
            href: branch_versions_url(represented, user_options.fetch(:base_url)) + "?pageSize=1"
          }
        end

        include Timestamps
      end
    end
  end
end
