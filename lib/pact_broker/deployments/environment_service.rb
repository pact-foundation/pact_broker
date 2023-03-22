require "pact_broker/deployments/environment"
require "securerandom"
require "pact_broker/pacticipants/generate_display_name"
require "pact_broker/string_refinements"
require "pact_broker/repositories/scopes"

module PactBroker
  module Deployments
    module EnvironmentService
      using PactBroker::StringRefinements
      extend PactBroker::Repositories::Scopes
      extend self

      def self.included(base)
        base.extend(self)
      end

      def next_uuid
        SecureRandom.uuid
      end

      def create(uuid, environment)
        environment.uuid = uuid
        if environment.display_name.blank?
          environment.display_name = PactBroker::Pacticipants::GenerateDisplayName.call(environment.name)
        end
        environment.save
      end

      def replace(uuid, environment)
        environment.uuid = uuid
        if environment.display_name.blank?
          environment.display_name = PactBroker::Pacticipants::GenerateDisplayName.call(environment.name)
        end
        environment.upsert
      end

      def find_all
        scope_for(PactBroker::Deployments::Environment).order(Sequel.function(:lower, :display_name)).all
      end

      def find(uuid)
        PactBroker::Deployments::Environment.where(uuid: uuid).single_record
      end

      def find_by_name(name)
        PactBroker::Deployments::Environment.where(name: name).single_record
      end

      def delete(uuid)
        PactBroker::Deployments::Environment.where(uuid: uuid).delete
      end

      def find_for_pacticipant(_pacticipant)
        find_all
      end

      def scope_for(scope)
        PactBroker.policy_scope!(scope)
      end
    end
  end
end
