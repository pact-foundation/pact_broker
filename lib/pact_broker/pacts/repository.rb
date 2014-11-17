require 'sequel'
require 'pact_broker/logging'
require 'ostruct'
require 'pact_broker/pacts/database_model'
require 'pact_broker/pacts/all_pacts'
require 'pact_broker/pacts/latest_pacts'

module PactBroker
  module Pacts
    class Repository

      include PactBroker::Logging

      def find_all_pacts_between consumer_name, options
        AllPacts
          .eager(:tags)
          .where(consumer_name: consumer_name, provider_name: options.fetch(:and))
          .reverse_order(:consumer_version_order)
          .collect(&:to_domain)
      end

      def find_by_version_and_provider version_id, provider_id
        AllPacts
          .eager(:tags)
          .where(consumer_version_id: version_id, provider_id: provider_id)
          .limit(1).collect(&:to_domain)[0]
      end

      def find_latest_pacts
        LatestPacts.collect(&:to_domain)
      end

      def find_latest_pact(consumer_name, provider_name, tag = nil)
        query = AllPacts
          .where(consumer_name: consumer_name, provider_name: provider_name)
        if tag
          query = query
            .join(:tags, {version_id: :consumer_version_id})
            .where('tags.name = ?', tag)
        end
        query.reverse_order(:consumer_version_order).limit(1).all.collect(&:to_domain_with_content)[0]
      end

      def find_pact consumer_name, consumer_version, provider_name
        AllPacts
          .eager(:tags)
          .where(consumer_name: consumer_name, provider_name: provider_name, consumer_version_number: consumer_version)
          .limit(1).collect(&:to_domain_with_content)[0]
      end

      def create params
        to_domain do
          pact_version_content = PactVersionContent.new(content: params[:json_content]).save
          DatabaseModel.new(
            version_id: params[:version_id],
            provider_id: params[:provider_id],
            pact_version_content: pact_version_content,
          ).save
        end
      end

      def update id, params
        to_domain do
          DatabaseModel.find(id: id).tap do | pact |
            pact.pact_version_content.update(content: params[:json_content])
            pact.update(updated_at: pact.pact_version_content.updated_at)
          end
        end
      end

      def find_previous_pact pact
        AllPacts
          .eager(:tags)
          .where(consumer_name: pact.consumer.name, provider_name: pact.provider.name)
          .where('consumer_version_order < ?', pact.consumer_version.order)
          .reverse_order(:consumer_version_order)
          .limit(1).collect(&:to_domain)[0]
      end

      private

      def to_domain
        database_model = yield
        database_model ? database_model.to_domain : nil
      end

    end
  end
end
