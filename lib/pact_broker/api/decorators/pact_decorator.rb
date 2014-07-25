require_relative 'base_decorator'

module PactBroker

  module Api

    module Decorators

      class PactDecorator < BaseDecorator

        property :createdAt, getter: lambda { |_|  created_at.xmlschema }
        property :updatedAt, getter: lambda { |_| updated_at.xmlschema }

        def to_hash(options = {})
          ::JSON.parse(represented.json_content).merge super
        end

      end
    end
  end
end