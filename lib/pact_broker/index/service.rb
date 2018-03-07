require 'pact_broker/repositories'
require 'pact_broker/logging'
require 'pact_broker/domain/index_item'
require 'pact_broker/matrix/latest_row'
require 'pact_broker/matrix/head_row'

module PactBroker

  module Index
    class Service

      extend PactBroker::Repositories
      extend PactBroker::Services
      extend PactBroker::Logging

      def self.find_index_items options = {}
        rows = []
        overall_latest_publication_ids = nil

        rows = PactBroker::Matrix::HeadRow
          .select_all_qualified
          .eager(:latest_triggered_webhooks)
          .eager(:webhooks)
          .order(:consumer_name, :provider_name)
          .eager(:consumer_version_tags)
          .eager(:provider_version_tags)

        if !options[:tags]
          rows = rows.where(consumer_version_tag_name: nil).all
          overall_latest_publication_ids = rows.collect(&:pact_publication_id)
        end

        if options[:tags]
          if options[:tags].is_a?(Array)
            rows = rows.where(consumer_version_tag_name: options[:tags]).or(consumer_version_tag_name: nil)
          end

          rows = rows.all
          overall_latest_publication_ids = rows.select{|r| !r[:consumer_version_tag_name] }.collect(&:pact_publication_id).uniq

          # Smoosh all the rows with matching pact publications together
          # and collect their consumer_head_tag_names
          rows = rows
            .group_by(&:pact_publication_id)
            .values
            .collect{|group| [group.last, group.collect{|r| r[:consumer_version_tag_name]}.compact] }
            .collect{ |(row, tag_names)| row.consumer_head_tag_names = tag_names; row }
        end

        index_items = []
        rows.sort.each do | row |
          tag_names = []
          if options[:tags]
            tag_names = row.consumer_version_tags.collect(&:name)
          end

          overall_latest = overall_latest_publication_ids.include?(row.pact_publication_id)
          latest_verification = if overall_latest
            verification_repository.find_latest_verification_for row.consumer_name, row.provider_name
          else
            tag_names.collect do | tag_name |
              verification_repository.find_latest_verification_for row.consumer_name, row.provider_name, tag_name
            end.compact.sort do | v1, v2 |
              # Some provider versions have nil orders, not sure why
              # Sort by execution_date instead of order
              v1.execution_date <=> v2.execution_date
            end.last
          end

          index_items << PactBroker::Domain::IndexItem.create(
            row.consumer,
            row.provider,
            row.pact,
            overall_latest,
            latest_verification,
            row.webhooks,
            row.latest_triggered_webhooks,
            row.consumer_head_tag_names,
            row.provider_version_tags.select(&:latest?)
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
