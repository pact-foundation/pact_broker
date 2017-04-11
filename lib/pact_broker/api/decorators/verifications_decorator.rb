require_relative 'base_decorator'
require_relative 'version_decorator'

module PactBroker
  module Api
    module Decorators

      class VerificationsDecorator < BaseDecorator

        collection :entries, as: :verifications, embedded: true, :extend => PactBroker::Api::Decorators::VerificationDecorator

        link :self do | context |
          {
            href: context.fetch(:resource_url),
            title: "Latest verifications for consumer #{context.fetch(:consumer_name)} version #{context.fetch(:consumer_version_number)}"
          }
        end
      end
    end
  end
end
