require 'pact_broker/repositories'
require 'pact_broker/logging'
require 'pact_broker/domain/relationship'

module PactBroker

  module Index
    class Service

      extend PactBroker::Repositories
      extend PactBroker::Services
      extend PactBroker::Logging

      def self.find_relationships options = {}
        pact_repository
          .find_latest_pacts
          .collect { | pact| build_relationship_rows(pact, options[:tags] || []) }
          .flatten
      end

      def self.build_relationship_rows(pact, tags)
        relationships = [build_latest_pact_relationship(pact, tags)]
        tags.each do | tag |
          relationships << build_relationship_for_tagged_pact(pact, tag)
        end
        relationships.compact
      end

      def self.build_latest_pact_relationship pact, tags
        latest_verification = verification_service.find_latest_verification_for(pact.consumer, pact.provider)
        webhooks = webhook_service.find_by_consumer_and_provider pact.consumer, pact.provider
        triggered_webhooks = webhook_service.find_latest_triggered_webhooks pact.consumer, pact.provider
        tag_names = pact.consumer_version_tag_names.select{ |name| tags.include?(name) }
        PactBroker::Domain::Relationship.create pact.consumer, pact.provider, pact, true, latest_verification, webhooks, triggered_webhooks, tag_names
      end

      def self.build_relationship_for_tagged_pact latest_pact, tag
        pact = pact_service.find_latest_pact consumer_name: latest_pact.consumer_name, provider_name: latest_pact.provider_name, tag: tag
        return nil unless pact
        return nil if pact.id == latest_pact.id
        verification = verification_repository.find_latest_verification_for pact.consumer_name, pact.provider_name, tag
        PactBroker::Domain::Relationship.create pact.consumer, pact.provider, pact, false, verification, [], [], [tag]
      end
    end
  end
end
