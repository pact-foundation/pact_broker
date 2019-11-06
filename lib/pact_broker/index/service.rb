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
        if options[:optimised]
          find_index_items_optimised(options)
        else
          find_index_items_original(options)
        end
      end

      def self.find_index_items_original options = {}
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

      def self.find_index_items_optimised options = {}
        pact_publication_ids = nil
        latest_verifications_for_cv_tags = nil

        if !options[:tags]
          # server side rendered index page without tags
          pact_publication_ids = latest_pact_publications.select(:id)
        else
          # server side rendered index page with tags=true or tags[]=a&tags=[]b
          if options[:tags].is_a?(Array)
            # TODO test for this
            pact_publication_ids = head_pact_publications_ids_for_tags(options[:tags])
            latest_verifications_for_cv_tags = PactBroker::Verifications::LatestVerificationForConsumerVersionTag
                                                    .eager(:provider_version)
                                                    .where(consumer_version_tag_name: options[:tags]).all
          else
            pact_publication_ids = head_pact_publications_ids
            latest_verifications_for_cv_tags = PactBroker::Verifications::LatestVerificationForConsumerVersionTag.eager(:provider_version).all
          end
        end

        latest_pact_publication_ids = latest_pact_publications.select(:id).all.collect{ |h| h[:id] }

        # We only need to know if a webhook exists for an integration, not what its properties are
        webhooks = PactBroker::Webhooks::Webhook.select(:consumer_id, :provider_id).distinct.all

        pact_publications = PactBroker::Pacts::PactPublication
          .where(id: pact_publication_ids)
          .select_all_qualified
          .eager(:consumer)
          .eager(:provider)
          .eager(:pact_version)
          .eager(integration: [{latest_verification: :provider_version}, :latest_triggered_webhooks])
          .eager(:consumer_version)
          .eager(latest_verification: { provider_version: :tags_with_latest_flag })
          .eager(:head_pact_tags)

        pact_publications.all.collect do | pact_publication |

          is_overall_latest_for_integration = latest_pact_publication_ids.include?(pact_publication.id)
          latest_verification = latest_verification_for_pseudo_branch(pact_publication, is_overall_latest_for_integration, latest_verifications_for_cv_tags, options[:tags])
          webhook = webhooks.find{ |webhook| webhook.is_for?(pact_publication.integration) }

          PactBroker::Domain::IndexItem.create(
            pact_publication.consumer,
            pact_publication.provider,
            pact_publication.to_domain_lightweight,
            is_overall_latest_for_integration,
            latest_verification,
            webhook ? [webhook]: [],
            pact_publication.integration.latest_triggered_webhooks,
            consumer_version_tags(pact_publication, options[:tags]),
            options[:tags] && latest_verification ? latest_verification.provider_version.tags_with_latest_flag.select(&:latest?) : []
          )
        end.sort
      end

      # Worst. Code. Ever.
      #
      def self.latest_verification_for_pseudo_branch(pact_publication, is_overall_latest, latest_verifications_for_cv_tags, tags_option)
        if tags_option == true
          latest_verifications_for_cv_tags
            .select{ | v | v.consumer_id == pact_publication.consumer_id && v.provider_id == pact_publication.provider_id && pact_publication.head_pact_tags.collect(&:name).include?(v.consumer_version_tag_name) }
            .sort{ |v1, v2| v1.id <=> v2.id }.last || (is_overall_latest && pact_publication.integration.latest_verification)
        elsif tags_option.is_a?(Array)
          latest_verifications_for_cv_tags
          .select{ | v | v.consumer_id == pact_publication.consumer_id && v.provider_id == pact_publication.provider_id && pact_publication.head_pact_tags.collect(&:name).include?(v.consumer_version_tag_name) && tags_option.include?(v.consumer_version_tag_name) }
          .sort{ |v1, v2| v1.id <=> v2.id }.last  || (is_overall_latest && pact_publication.integration.latest_verification)
        else
          pact_publication.integration.latest_verification
        end
      end

      def self.consumer_version_tags(pact_publication, tags_option)
        if tags_option == true
          pact_publication.head_pact_tags.collect(&:name)
        elsif tags_option.is_a?(Array)
          pact_publication.head_pact_tags.collect(&:name) & tags_option
        else
          []
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

      def self.latest_pact_publications
        db[:latest_pact_publications]
      end

      def self.head_pact_publications_ids
        db[:head_pact_tags].select(Sequel[:pact_publication_id].as(:id)).union(db[:latest_pact_publications].select(:id)).limit(500)
      end

      def self.head_pact_publications_ids_for_tags(tag_names)
        db[:head_pact_tags].select(Sequel[:pact_publication_id].as(:id)).where(name: tag_names).union(db[:latest_pact_publications].select(:id)).limit(500)
      end

      def self.db
        PactBroker::Pacts::PactPublication.db
      end
    end
  end
end
