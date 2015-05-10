require 'pact_broker/repositories'
require 'pact_broker/services'

module PactBroker
  module Pacts
    module Service

      extend self

      extend PactBroker::Repositories
      extend PactBroker::Services

      def find_latest_pact params
        pact_repository.find_latest_pact(params[:consumer_name], params[:provider_name], params[:tag])
      end

      def find_latest_pacts
        pact_repository.find_latest_pacts
      end

      def find_pact params
        pact_repository.find_pact(params[:consumer_name], params[:consumer_version_number], params[:provider_name])
      end

      def delete params
        pact_repository.delete(params)
      end

      def create_or_update_pact params
        provider = pacticipant_repository.find_by_name_or_create params[:provider_name]
        consumer = pacticipant_repository.find_by_name_or_create params[:consumer_name]
        consumer_version = version_repository.find_by_pacticipant_id_and_number_or_create consumer.id, params[:consumer_version_number]
        existing_pact = pact_repository.find_by_version_and_provider(consumer_version.id, provider.id)

        if existing_pact
          update_pact params, existing_pact
        else
          create_pact params, consumer_version, provider
        end
      end

      def find_all_pact_versions_between consumer, options
        pact_repository.find_all_pact_versions_between consumer, options
      end

      def find_latest_pact_versions_for_provider provider_name, options = {}
        pact_repository.find_latest_pact_versions_for_provider provider_name, options
      end

      def find_previous_distinct_pact_version params
        pact = find_pact params
        return nil if pact.nil?
        pact_repository.find_previous_distinct_pact pact
      end

      def find_distinct_pacts_between consumer, options
        # Assumes pacts are sorted from newest to oldest
        all = pact_repository.find_all_pact_versions_between consumer, options
        distinct = []
        (0...all.size).each do | i |
          if i == all.size - 1
            distinct << all[i]
          else
            if all[i].json_content != all[i+1].json_content
              distinct << all[i]
            end
          end
        end
        distinct
      end

      def pact_has_changed_since_previous_version? pact
        previous_pact = pact_repository.find_previous_pact pact
        previous_pact && pact.json_content != previous_pact.json_content
      end

      private

      def update_pact params, existing_pact
        updated_pact = pact_repository.update existing_pact.id, params

        if existing_pact.json_content != updated_pact.json_content
          webhook_service.execute_webhooks updated_pact
        end

        updated_pact
      end

      def create_pact params, version, provider
        pact = pact_repository.create json_content: params[:json_content], version_id: version.id, provider_id: provider.id
        trigger_webhooks pact
        pact
      end

      def trigger_webhooks pact
        if pact_has_changed_since_previous_version? pact
          webhook_service.execute_webhooks pact
        end
      end

    end
  end
end