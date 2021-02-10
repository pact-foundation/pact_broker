require 'pact_broker/api/decorators/base_decorator'
require 'pact_broker/api/decorators/environment_decorator'
require 'pact_broker/deployments/environment'

module PactBroker
  module Api
    module Decorators
      class EnvironmentsDecorator < BaseDecorator

        collection :entries, :as => :environments, :class => PactBroker::Deployments::Environment, :extend => PactBroker::Api::Decorators::EnvironmentDecorator, embedded: true


      end
    end
  end
end
