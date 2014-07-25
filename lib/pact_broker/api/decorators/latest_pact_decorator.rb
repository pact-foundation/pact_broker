require_relative 'pact_details_decorator'

module PactBroker

  module Api

    module Decorators

      class LatestPactDecorator < PactDetailsDecorator

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