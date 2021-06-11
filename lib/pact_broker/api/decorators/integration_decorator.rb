require_relative "base_decorator"
require "pact_broker/api/pact_broker_urls"

module PactBroker
  module Api
    module Decorators
      class IntegrationDecorator < BaseDecorator
        include PactBroker::Api::PactBrokerUrls

        property :consumer do
          property :name
        end

        property :provider do
          property :name
        end

        property :verificationStatus, getter: ->(represented:, **) { represented.verification_status_for_latest_pact.to_s }

        link "pb:dashboard" do | options |
          {
            title: "BETA: Pacts to show on the dashboard",
            href: dashboard_url_for_integration(represented.consumer.name, represented.provider.name, options.fetch(:base_url))
          }
        end

        link "pb:matrix" do | options |
          {
            title: "Matrix of pacts/verification results for #{represented.consumer.name} and #{represented.provider.name}",
            href: matrix_url(represented.consumer.name, represented.provider.name, options.fetch(:base_url))
          }
        end

        link "pb:group" do | options |
          {
            href: group_url(represented.consumer.name, options.fetch(:base_url))
          }
        end
      end
    end
  end
end
