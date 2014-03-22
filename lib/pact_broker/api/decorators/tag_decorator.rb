require_relative 'base_decorator'
require_relative 'pact_pacticipant_decorator'

module PactBroker

  module Api

    module Decorators

      class TagDecorator < BaseDecorator

        link :self do | options |
          tag_url(options[:base_url], represented)
        end

      end
    end
  end
end