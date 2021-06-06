require "pact_broker/api/decorators/base_decorator"

module PactBroker
  module Api
    module Decorators
      class ReleasedVersionDecorator < BaseDecorator
        property :uuid
        property :currently_supported, camelize: true

        include Timestamps
      end
    end
  end
end
