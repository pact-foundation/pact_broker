require 'roar/json'

module PactBroker

  module Api

    module Decorators

      module Timestamps

        include Roar::JSON

        property :optional_updated_at, as: :updatedAt, exec_context: :decorator, writeable: false
        property :createdAt, getter: lambda { |_|  created_at.xmlschema }, writeable: false

        def optional_updated_at
          if represented.respond_to?(:updated_at) && represented.updated_at != represented.created_at
            represented.updated_at.xmlschema
          end
        end
      end
    end
  end
end
