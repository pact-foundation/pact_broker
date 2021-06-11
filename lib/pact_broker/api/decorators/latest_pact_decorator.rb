require_relative "pact_details_decorator"
require "pact_broker/api/decorators/timestamps"

module PactBroker

  module Api

    module Decorators

      class LatestPactDecorator < PactDetailsDecorator

        include Timestamps

        links :self do | options |
          [
            {
              href: latest_pact_url(options[:base_url], represented)
            },{
              href: pact_url(options[:base_url], represented)
            }
          ]
        end

      end
    end
  end
end
