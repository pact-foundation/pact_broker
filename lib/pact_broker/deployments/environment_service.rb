require 'pact_broker/deployments/environment'
require 'securerandom'
require 'pact_broker/pacticipants/generate_display_name'
require 'pact_broker/string_refinements'

module PactBroker
  module Deployments
    module EnvironmentService
      using PactBroker::StringRefinements

      def self.next_uuid
        SecureRandom.uuid
      end

      def self.create(uuid, environment)
        environment.uuid = uuid
        if environment.display_name.blank?
          environment.display_name = PactBroker::Pacticipants::GenerateDisplayName.call(environment.name)
        end
        environment.save
      end

      def self.update(uuid, environment)
        environment.uuid = uuid
        if environment.display_name.blank?
          environment.display_name = PactBroker::Pacticipants::GenerateDisplayName.call(environment.name)
        end
        environment.upsert
      end

      def self.find_all
        PactBroker::Deployments::Environment.order(Sequel.function(:lower, :display_name)).all
      end

      def self.find(uuid)
        PactBroker::Deployments::Environment.where(uuid: uuid).single_record
      end

      def self.find_by_name(name)
        PactBroker::Deployments::Environment.where(name: name).single_record
      end

      def self.delete(uuid)
        PactBroker::Deployments::Environment.where(uuid: uuid).delete
      end

      def self.find_for_pacticipant(_pacticipant)
        find_all
      end
    end
  end
end
