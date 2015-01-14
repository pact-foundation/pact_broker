require 'digest/sha1'
require 'sequel'
require 'ostruct'
require 'pact_broker/logging'
require 'pact_broker/pacts/database_model'
require 'pact_broker/pacts/all_pacts'
require 'pact_broker/pacts/latest_pacts'
require 'pact/shared/json_differ'

module PactBroker
  module Pacts
    class Repository

      include PactBroker::Logging

      def create params
        DatabaseModel.new(
          version_id: params[:version_id],
          provider_id: params[:provider_id],
          pact_version_content: find_or_create_pact_version_content(params[:json_content]),
        ).save.to_domain
      end

      def update id, params
        DatabaseModel.find(id: id).tap do | pact |
          pact_version_content = find_or_create_pact_version_content(params[:json_content])
          pact.update(pact_version_content: pact_version_content)
        end.to_domain
      end

      def delete params
        id = AllPacts
          .consumer(params.consumer_name)
          .provider(params.provider_name)
          .consumer_version_number(params.consumer_version_number)
          .limit(1).first.id
        DatabaseModel.where(id: id).delete
      end

      def find_all_pacts_between consumer_name, options
        AllPacts
          .eager(:tags)
          .consumer(consumer_name)
          .provider(options.fetch(:and))
          .reverse_order(:consumer_version_order)
          .collect(&:to_domain)
      end

      def find_by_version_and_provider version_id, provider_id
        AllPacts
          .eager(:tags)
          .where(consumer_version_id: version_id, provider_id: provider_id)
          .limit(1).collect(&:to_domain_with_content)[0]
      end

      def find_latest_pacts
        LatestPacts.collect(&:to_domain)
      end

      def find_latest_pact(consumer_name, provider_name, tag = nil)
        query = AllPacts
          .consumer(consumer_name)
          .provider(provider_name)
        query = query.tag(tag) unless tag.nil?
        query.latest.all.collect(&:to_domain_with_content)[0]
      end

      def find_pact consumer_name, consumer_version, provider_name
        AllPacts
          .eager(:tags)
          .consumer(consumer_name)
          .provider(provider_name)
          .consumer_version_number(consumer_version)
          .limit(1).collect(&:to_domain_with_content)[0]
      end

      def find_previous_pact pact
        AllPacts
          .eager(:tags)
          .consumer(pact.consumer.name)
          .provider(pact.provider.name)
          .consumer_version_order_before(pact.consumer_version.order)
          .latest.collect(&:to_domain_with_content)[0]
      end

      def find_next_pact pact
        AllPacts
          .eager(:tags)
          .consumer(pact.consumer.name)
          .provider(pact.provider.name)
          .consumer_version_order_after(pact.consumer_version.order)
          .earliest.collect(&:to_domain_with_content)[0]
      end

      def find_previous_distinct_pact pact
        previous, current = nil, pact
        loop do
          previous = find_previous_distinct_pact_by_sha current
          return previous if previous.nil? || different?(current, previous)
          current = previous
        end
      end

      private

      def find_previous_distinct_pact_by_sha pact
        current_pact_content_sha =
          AllPacts.select(:pact_version_content_sha)
          .consumer(pact.consumer.name)
          .provider(pact.provider.name)
          .consumer_version_number(pact.consumer_version_number)
          .limit(1)

        AllPacts
          .eager(:tags)
          .consumer(pact.consumer.name)
          .provider(pact.provider.name)
          .consumer_version_order_before(pact.consumer_version.order)
          .where('pact_version_content_sha != ?', current_pact_content_sha)
          .latest
          .collect(&:to_domain_with_content)[0]
      end

      def different? pact, other_pact
        Pact::JsonDiffer.(pact.content_hash, other_pact.content_hash, allow_unexpected_keys: false).any?
      end

      def find_or_create_pact_version_content json_content
        sha = Digest::SHA1.hexdigest(json_content)
        PactVersionContent.find(sha: sha) || create_pact_version_content(sha, json_content)
      end

      def create_pact_version_content sha, json_content
        PactBroker.logger.debug("Creating new PactVersionContent for sha #{sha}")
        pact_version_content = PactVersionContent.new(content: json_content)
        pact_version_content[:sha] = sha
        pact_version_content.save
      end

    end
  end
end
