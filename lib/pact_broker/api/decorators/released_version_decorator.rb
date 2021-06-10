require "pact_broker/api/decorators/base_decorator"

module PactBroker
  module Api
    module Decorators
      class ReleasedVersionDecorator < BaseDecorator
        property :uuid
        property :currently_supported, camelize: true
        include Timestamps
        property :supportEndedAt, getter: lambda { |_|  support_ended_at ? FormatDateTime.call(support_ended_at) : nil }, writeable: false
      end
    end
  end
end
