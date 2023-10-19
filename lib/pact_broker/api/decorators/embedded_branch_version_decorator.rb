require_relative "base_decorator"
require_relative "timestamps"

module PactBroker
  module Api
    module Decorators
      class EmbeddedBranchVersionDecorator < BaseDecorator
        property :branch_name, as: :name # TODO rename this to branchName in next major version
        property :latest?, as: :latest

        link :self do | options |
          {
            title: "Branch version",
            name: represented.branch_name,
            href: branch_version_url(represented, options[:base_url])
          }
        end
      end
    end
  end
end
