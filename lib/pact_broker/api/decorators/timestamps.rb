require "roar/json"
require "pact_broker/api/decorators/format_date_time"

module PactBroker
  module Api
    module Decorators
      module Timestamps
        include Roar::JSON

        property :optional_updated_at, as: :updatedAt, exec_context: :decorator, writeable: false
        property :createdAt, getter: lambda { |_|  FormatDateTime.call(created_at) }, writeable: false

        def optional_updated_at
          if represented.respond_to?(:updated_at) && represented.updated_at != represented.created_at
            FormatDateTime.call(represented.updated_at)
          end
        end
      end
    end
  end
end
