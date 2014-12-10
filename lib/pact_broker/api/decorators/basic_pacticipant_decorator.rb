require_relative 'base_decorator'

module PactBroker

  module Api

    module Decorators

      class BasicPacticipantRepresenter < BaseDecorator

        property :name

        link :self do | options |
          pacticipant_url(options[:base_url], represented)
        end

      end
    end
  end
end
