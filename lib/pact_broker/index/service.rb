require 'pact_broker/repositories'
require 'pact_broker/logging'
require 'pact_broker/domain/index_item'
require 'pact_broker/matrix/latest_row'

module PactBroker

  module Index
    class Service

      extend PactBroker::Repositories
      extend PactBroker::Services
      extend PactBroker::Logging

      def self.find_index_items options = {}
        rows = []

        if !options[:tags]
        rows = PactBroker::Matrix::LatestRow
          .select_all_qualified
          .join(:latest_pact_publications, {consumer_id: :consumer_id, provider_id: :provider_id, consumer_version_order: :consumer_version_order})
          .eager(:latest_triggered_webhooks)
          .eager(:webhooks)
          .order(:consumer_name, :provider_name)
          .eager(:consumer_version_tags)
          .all
        end

        if options[:tags]
          tagged_rows = PactBroker::Matrix::Row
            .select_all_qualified
            .select_append(Sequel[:head_pact_publications][:tag_name])
            .join(:head_pact_publications, {consumer_id: :consumer_id, provider_id: :provider_id, consumer_version_order: :consumer_version_order})
            .eager(:latest_triggered_webhooks)
            .eager(:webhooks)
            .order(:consumer_name, :provider_name)
            .eager(:consumer_version_tags)
            .eager(:latest_verification_tags)

            if options[:tags].is_a?(Array)
              tagged_rows = tagged_rows.where(Sequel[:head_pact_publications][:tag_name] => options[:tags]).or(Sequel[:head_pact_publications][:tag_name] => nil)
            end

            tagged_rows = tagged_rows.all
              .group_by(&:pact_publication_id)
              .values
              .collect{|group| [group.last, group.collect{|r| r[:tag_name]}.compact] }
              .collect{ |(row, tag_names)| row.consumer_head_tag_names = tag_names; row }

          rows = tagged_rows
        end

        index_items = []
        rows.sort.each do | row |
          tag_names = []
          if options[:tags]
            tag_names = row.consumer_version_tags.collect(&:name)
            if options[:tags].is_a?(Array)
             tag_names = tag_names & options[:tags]
            end
          end
          previous_index_item_for_same_consumer_and_provider = index_items.last && index_items.last.consumer_name == row.consumer_name && index_items.last.provider_name == row.provider_name
          index_items << PactBroker::Domain::IndexItem.create(row.consumer, row.provider,
            row.pact,
            !previous_index_item_for_same_consumer_and_provider,
            row.latest_verification,
            row.webhooks,
            row.latest_triggered_webhooks,
            tag_names,
            row.latest_verification_tags
            )
        end

        index_items
      end

      def self.tags_for(pact, options)
        if options[:tags] == true
          tag_service.find_all_tag_names_for_pacticipant(pact.consumer_name)
        elsif options[:tags].is_a?(Array)
          options[:tags]
        else
          []
        end
      end

      def self.build_index_item_rows(pact, tags)
        index_items = [build_latest_pact_index_item(pact, tags)]
        tags.each do | tag |
          index_items << build_index_item_for_tagged_pact(pact, tag)
        end
        index_items.compact
      end

      def self.build_latest_pact_index_item pact, tags
        latest_verification = verification_service.find_latest_verification_for(pact.consumer, pact.provider)
        webhooks = webhook_service.find_by_consumer_and_provider pact.consumer, pact.provider
        triggered_webhooks = webhook_service.find_latest_triggered_webhooks pact.consumer, pact.provider
        tag_names = pact.consumer_version_tag_names.select{ |name| tags.include?(name) }
        PactBroker::Domain::IndexItem.create pact.consumer, pact.provider, pact, true, latest_verification, webhooks, triggered_webhooks, tag_names
      end

      def self.build_index_item_for_tagged_pact latest_pact, tag
        pact = pact_service.find_latest_pact consumer_name: latest_pact.consumer_name, provider_name: latest_pact.provider_name, tag: tag
        return nil unless pact
        return nil if pact.id == latest_pact.id
        verification = verification_repository.find_latest_verification_for pact.consumer_name, pact.provider_name, tag
        PactBroker::Domain::IndexItem.create pact.consumer, pact.provider, pact, false, verification, [], [], [tag]
      end
    end
  end
end
