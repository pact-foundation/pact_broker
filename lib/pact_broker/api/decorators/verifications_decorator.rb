require_relative 'base_decorator'
require_relative 'version_decorator'

module PactBroker
  module Api
    module Decorators

      class VerificationsDecorator < BaseDecorator

        property :success, exec_context: :decorator, if: :any_verifications?
        collection :entries, as: :'verification-results', embedded: true, :extend => PactBroker::Api::Decorators::VerificationDecorator

        link :self do | context |
          {
            href: context.fetch(:resource_url),
            title: "Latest verification results for consumer #{context.fetch(:consumer_name)} version #{context.fetch(:consumer_version_number)}"
          }
        end

        def success
          represented.collect(&:success).all?
        end

        def any_verifications? context
          represented.any?
        end
      end
    end
  end
end
