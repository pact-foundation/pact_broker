require 'pact_broker/repositories'
require 'pact_broker/logging'
require 'pact_broker/domain/index_item'
require 'pact_broker/matrix/head_row'
require 'pact_broker/matrix/aggregated_row'

module PactBroker

  module Index
    class Service

      extend PactBroker::Repositories
      extend PactBroker::Services
      extend PactBroker::Logging

      def self.find_index_items options = {}
        rows = PactBroker::Matrix::HeadRow
          .select_all_qualified
          .eager(:latest_triggered_webhooks)
          .eager(:webhooks)
          .order(:consumer_name, :provider_name)
          .eager(:verification)

        if !options[:tags]
          rows = rows.where(consumer_version_tag_name: nil)
        else
          if options[:tags].is_a?(Array)
            rows = rows.where(consumer_version_tag_name: options[:tags]).or(consumer_version_tag_name: nil)
          end
          rows = rows.eager(:consumer_version_tags)
                .eager(:provider_version_tags)
                .eager(:latest_verification_for_consumer_version_tag)
        end
        rows = rows.all.group_by(&:pact_publication_id).values.collect{ | rows| Matrix::AggregatedRow.new(rows) }

        rows.sort.collect do | row |
          PactBroker::Domain::IndexItem.create(
            row.consumer,
            row.provider,
            row.pact,
            row.overall_latest?,
            options[:tags] ? row.latest_verification : row.verification,
            row.webhooks,
            row.latest_triggered_webhooks,
            options[:tags] ? row.consumer_head_tag_names : [],
            options[:tags] ? row.provider_version_tags.select(&:latest?) : []
          )
        end
      end
    end
  end
end
