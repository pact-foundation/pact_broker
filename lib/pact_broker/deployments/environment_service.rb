require 'pact_broker/deployments/environment'
require 'securerandom'

module PactBroker
  module Deployments
    module EnvironmentService

      def self.next_uuid
        SecureRandom.uuid
      end

      def self.create(uuid, environment)
        environment.uuid = uuid
        environment.save
      end

      def self.update(uuid, environment)
        environment.uuid = uuid
        environment.upsert
      end

      def self.find_all
        PactBroker::Deployments::Environment.order(Sequel.function(:lower, :label)).all
      end

      def self.find(uuid)
        PactBroker::Deployments::Environment.where(uuid: uuid).single_record
      end

      def self.delete(uuid)
        PactBroker::Deployments::Environment.where(uuid: uuid).delete
      end
    end
  end
end
