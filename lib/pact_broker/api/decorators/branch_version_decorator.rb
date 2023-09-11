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

        link :"pb:branch" do | user_options |
          {
            title: "Branch",
            name: represented.branch.name,
            href: branch_url(represented.branch, user_options.fetch(:base_url))
          }
        end

        link :"pb:version" do | user_options |
          {
            title: "Version",
            name: represented.version.number,
            href: version_url(user_options.fetch(:base_url), represented.version)
          }
        end

        include Timestamps
      end
    end
  end
end
