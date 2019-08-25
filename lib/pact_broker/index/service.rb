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

        rows = rows.consumer(options[:consumer_name]) if options[:consumer_name]
        rows = rows.provider(options[:provider_name]) if options[:provider_name]

        if !options[:tags]
          rows = rows.where(consumer_version_tag_name: nil)
        else
          if options[:tags].is_a?(Array)
            rows = rows.where(consumer_version_tag_name: options[:tags]).or(consumer_version_tag_name: nil)
          end
          rows = rows.eager(:consumer_version_tags)
                .eager(:provider_version_tags)
                .eager(:latest_verification_for_consumer_version_tag)
                .eager(:latest_verification_for_consumer_and_provider)
        end
        rows = rows.all.group_by(&:pact_publication_id).values.collect{ | rows| Matrix::AggregatedRow.new(rows) }



        rows.sort.collect do | row |
          # The concept of "stale" (the pact used to be verified but then it changed and we haven't got
          # a new verification result yet) only really make sense if we're trying to summarise
          # the latest state of an integration. Once we start showing multiple pacts for each
          # integration (ie. the latest for each tag) then each pact version is either verified,
          # or it's not verified.
          # For backwards compatiblity with the existing UI, don't change the 'stale' concept for the OSS
          # UI - just ensure we don't use it for the new dashboard endpoint with the consumer/provider specified.
          latest_verification = if options[:dashboard]
            row.latest_verification_for_pact_version
          else
            row.latest_verification_for_pseudo_branch
          end

          # TODO simplify. Do we really need 3 layers of abstraction?
          PactBroker::Domain::IndexItem.create(
            row.consumer,
            row.provider,
            row.pact,
            row.overall_latest?,
            latest_verification,
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
