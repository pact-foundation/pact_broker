require_relative "base_decorator"

module PactBroker
  module Api
    module Decorators
      class NoticesDecorator < BaseDecorator
        property :entries, as: :notices, getter: ->(represented:, **) { represented.collect(&:to_h) }
      end
    end
  end
end
