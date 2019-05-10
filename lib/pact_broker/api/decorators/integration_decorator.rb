require_relative 'base_decorator'

module PactBroker
  module Api
    module Decorators
      class IntegrationDecorator < BaseDecorator
        property :consumer do
          property :name
        end

        property :provider do
          property :name
        end
      end
    end
  end
end
