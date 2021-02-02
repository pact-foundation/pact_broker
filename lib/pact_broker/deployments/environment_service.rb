require 'pact_broker/deployments/environment'

module PactBroker
  module Deployments
    module EnvironmentService
      def self.create(name, environment)
        environment.name = name
        environment.save
      end

      def self.update(name, environment)
        environment.name = name
        environment.upsert
      end

      def self.find(name)
        PactBroker::Deployments::Environment.where(name: name).single_record
      end

      def self.delete(name)
        PactBroker::Deployments::Environment.where(name: name).delete
      end
    end
  end
end
