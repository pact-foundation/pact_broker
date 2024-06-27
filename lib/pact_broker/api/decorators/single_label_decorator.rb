require_relative "base_decorator"

module PactBroker
  module Api
    module Decorators
      class SingleLabelDecorator < BaseDecorator

        property :name

      end
    end
  end
end
