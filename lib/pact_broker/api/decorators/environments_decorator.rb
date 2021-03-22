require 'pact_broker/api/decorators/base_decorator'
require 'pact_broker/api/decorators/environment_decorator'
require 'pact_broker/deployments/environment'

module PactBroker
  module Api
    module Decorators
      class EnvironmentsDecorator < BaseDecorator

        collection :entries, :as => :environments, :class => PactBroker::Deployments::Environment, :extend => PactBroker::Api::Decorators::EnvironmentDecorator, embedded: true

        link :self do | options |
          {
            title: 'Environments',
            href: options[:resource_url]
          }
        end

        links :'pb:environments' do | user_options |
          represented.collect do | environment |
            {
              title: "Environment",
              name: environment.name,
              href: environment_url(environment, user_options.fetch(:base_url))
            }
          end
        end
      end
    end
  end
end
