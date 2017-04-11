require_relative 'base_decorator'
require_relative 'version_decorator'

module PactBroker
  module Api
    module Decorators

      class VerificationsDecorator < BaseDecorator

        collection :entries, as: :verifications, embedded: true, :extend => PactBroker::Api::Decorators::VerificationDecorator

        link :self do | context |
          {
            href: context[:resource_url],
            title: "Latest verifications for consumer #{context[:consumer_name]} version #{context[:consumer_version_number]}"
          }
        end
      end
    end
  end
end
