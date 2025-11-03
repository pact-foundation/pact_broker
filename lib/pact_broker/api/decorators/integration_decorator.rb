require_relative "base_decorator"

module PactBroker
  module Api
    module Decorators
      class IntegrationDecorator < BaseDecorator
        include PactBroker::Api::PactBrokerUrls

        # TODO should be embedded in v3
        property :consumer do
          property :name
        end

        # TODO should be embedded in v3
        property :provider do
          property :name
        end

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

        link "pb:delete_integration" do | options |
          {
            title: "Delete the integration between #{represented.consumer.name} and #{represented.provider.name}",
            href: integration_url(represented.consumer.name, represented.provider.name, options.fetch(:base_url))
          }
        end
      end
    end
  end
end

