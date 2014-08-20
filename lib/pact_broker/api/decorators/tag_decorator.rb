require_relative 'base_decorator'
require_relative 'pact_pacticipant_decorator'

module PactBroker

  module Api

    module Decorators

      class TagDecorator < BaseDecorator

        property :createdAt, getter: lambda { |_| created_at ? created_at.xmlschema : nil }
        property :updatedAt, getter: lambda { |_| updated_at ? updated_at.xmlschema : nil }

        link :self do | options |
          tag_url(options[:base_url], represented)
        end

      end
    end
  end
end