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

      # This method provides data for both the OSS server side rendered index (with and without tags)
      # and the Pactflow UI. It really needs to be broken into to separate methods, as it's getting too messy
      # supporting both

      def self.find_index_items options = {}
        rows = PactBroker::Matrix::HeadRow
          .select_all_qualified
          .eager(:latest_triggered_webhooks)
          .eager(:webhooks)

        if !options[:tags]
          # server side rendered index page without tags
          rows = rows.where(consumer_version_tag_name: nil)
        else
          # server side rendered index page with tags=true or tags[]=a&tags=[]b
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
          # TODO simplify. Do we really need 3 layers of abstraction?
          PactBroker::Domain::IndexItem.create(
            row.consumer,
            row.provider,
            row.pact,
            row.overall_latest?,
            row.latest_verification_for_pseudo_branch,
            row.webhooks,
            row.latest_triggered_webhooks,
            options[:tags] ? row.consumer_head_tag_names : [],
            options[:tags] ? row.provider_version_tags.select(&:latest?) : []
          )
        end
      end

      def self.find_index_items_for_api(consumer_name: nil, provider_name: nil, **ignored)
        rows = PactBroker::Matrix::HeadRow
          .eager(:consumer_version_tags)
          .eager(:provider_version_tags)
          .select_all_qualified

        rows = rows.consumer(consumer_name) if consumer_name
        rows = rows.provider(provider_name) if provider_name

        rows = rows.all.group_by(&:pact_publication_id).values.collect{ | rows| Matrix::AggregatedRow.new(rows) }

        rows.sort.collect do | row |
          # TODO separate this model from IndexItem
          # webhook status not currently displayed in Pactflow UI, so don't query for it.
          PactBroker::Domain::IndexItem.create(
            row.consumer,
            row.provider,
            row.pact,
            row.overall_latest?,
            row.latest_verification_for_pact_version,
            [],
            [],
            row.consumer_head_tag_names,
            row.provider_version_tags.select(&:latest?)
          )
        end
      end
    end
  end
end
