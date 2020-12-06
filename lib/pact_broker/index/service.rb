require 'pact_broker/repositories'
require 'pact_broker/logging'
require 'pact_broker/domain/index_item'
require 'pact_broker/matrix/head_row'
require 'pact_broker/matrix/aggregated_row'
require 'pact_broker/repositories/helpers'
require 'pact_broker/index/page'

module PactBroker
  module Index
    class Service
      extend PactBroker::Repositories
      extend PactBroker::Services
      extend PactBroker::Logging

      COLS = [:id, :consumer_name, :provider_name, :consumer_version_order]
      LATEST_PPS = Sequel::Model.db[:latest_pact_publications].select(*COLS)
      LATEST_TAGGED_PPS = Sequel::Model.db[:latest_tagged_pact_publications].select(*COLS)
      HEAD_PP_ORDER_COLUMNS = [
          Sequel.asc(Sequel.function(:lower, :consumer_name)),
          Sequel.desc(:consumer_version_order),
          Sequel.asc(Sequel.function(:lower, :provider_name))
        ].freeze
      DEFAULT_PAGE_SIZE = 30
      DEFAULT_PAGE_NUMBER = 1

      # This method provides data for both the OSS server side rendered index (with and without tags)
      # and the Pactflow UI. It really needs to be broken into to separate methods, as it's getting too messy
      # supporting both

      def self.pact_publication_scope
        PactBroker.policy_scope!(PactBroker::Pacts::PactPublication)
      end

      def self.find_all_index_items
        # Is there a better way to do this? Setting a page_size of nil or -1 doesn't work
        # If we get to 100000000000 index items, we're probably going to have bigger issues...
        find_index_items(page_number: 1, page_size: 100000000000)
      end

      def self.find_index_items options = {}
        latest_verifications_for_cv_tags = latest_verifications_for_consumer_version_tags(options)
        latest_pact_publication_ids = latest_pact_publications.select(:id).all.collect{ |h| h[:id] }

        # We only need to know if a webhook exists for an integration, not what its properties are
        webhooks = PactBroker::Webhooks::Webhook.select(:consumer_id, :provider_id).distinct.all

        pact_publication_ids = head_pact_publication_ids(options)
        pagination_record_count = pact_publication_ids.pagination_record_count

        pact_publications = pact_publication_scope
          .where(id: pact_publication_ids)
          .select_all_qualified
          .eager(:consumer)
          .eager(:provider)
          .eager(:pact_version)
          .eager(integration: [{latest_verification: :provider_version}, :latest_triggered_webhooks])
          .eager(:consumer_version)
          .eager(latest_verification: { provider_version: :tags_with_latest_flag })
          .eager(:head_pact_tags)

        index_items = pact_publications.all.collect do | pact_publication |
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
            options[:tags] && latest_verification ? latest_verification.provider_version.head_tags : []
          )
        end.sort

        Page.new(index_items, pagination_record_count)
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
        latest_pact_publication_ids = latest_pact_publications.select(:id).all.collect{ |h| h[:id] }
        pact_publication_ids = head_pact_publication_ids(consumer_name: consumer_name, provider_name: provider_name, tags: true)

        pact_publications = pact_publication_scope
          .where(id: pact_publication_ids)
          .select_all_qualified
          .eager(:consumer)
          .eager(:provider)
          .eager(:pact_version)
          .eager(:consumer_version)
          .eager(latest_verification: { provider_version: :tags_with_latest_flag })
          .eager(:head_pact_tags)


        pact_publications.all.collect do | pact_publication |

          is_overall_latest_for_integration = latest_pact_publication_ids.include?(pact_publication.id)

          PactBroker::Domain::IndexItem.create(
            pact_publication.consumer,
            pact_publication.provider,
            pact_publication.to_domain_lightweight,
            is_overall_latest_for_integration,
            pact_publication.latest_verification,
            [],
            [],
            pact_publication.head_pact_tags.collect(&:name),
            pact_publication.latest_verification ? pact_publication.latest_verification.provider_version.tags_with_latest_flag.select(&:latest?) : []
          )
        end.sort
      end

      def self.latest_pact_publications
        db[:latest_pact_publications]
      end

      def self.db
        PactBroker::Pacts::PactPublication.db
      end

      def self.head_pact_publication_ids(options = {})
        query = if options[:tags].is_a?(Array)
          LATEST_PPS.union(LATEST_TAGGED_PPS.where(tag_name: options[:tags]))
        elsif options[:tags]
          LATEST_PPS.union(LATEST_TAGGED_PPS)
        else
          LATEST_PPS
        end

        if options[:consumer_name]
          query = query.where(PactBroker::Repositories::Helpers.name_like(:consumer_name, options[:consumer_name]))
        end

        if options[:provider_name]
          query = query.where(PactBroker::Repositories::Helpers.name_like(:provider_name, options[:provider_name]))
        end

        query.order(*HEAD_PP_ORDER_COLUMNS)
          .paginate(options[:page_number] || DEFAULT_PAGE_NUMBER, options[:page_size] || DEFAULT_PAGE_SIZE)
          .select(:id)
      end

      def self.latest_verifications_for_consumer_version_tags(options)
        # server side rendered index page with tags[]=a&tags=[]b
        if options[:tags].is_a?(Array)
          PactBroker::Verifications::LatestVerificationForConsumerVersionTag
            .eager(:provider_version)
            .where(consumer_version_tag_name: options[:tags])
            .all
        elsif options[:tags] # server side rendered index page with tags=true
          PactBroker::Verifications::LatestVerificationForConsumerVersionTag
            .eager(:provider_version)
            .all
        else
          nil # should not be used
        end
      end
    end
  end
end
