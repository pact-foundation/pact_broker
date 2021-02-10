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
        latest_pp_ids = latest_pact_publication_ids

        # We only need to know if a webhook exists for an integration, not what its properties are
        webhooks = PactBroker::Webhooks::Webhook.select(:consumer_id, :provider_id).distinct.all

        pact_publication_query = head_pact_publications(options)
        pagination_record_count = pact_publication_query.pagination_record_count

        pact_publications = pact_publication_query
          .eager(:consumer)
          .eager(:provider)
          .eager(:pact_version)
          .eager(integration: [{latest_verification: :provider_version}, :latest_triggered_webhooks])
          .eager(consumer_version: [:latest_version_for_branch, { tags: :head_tag }])
          .eager(latest_verification: { provider_version: [:latest_version_for_branch, { tags: :head_tag } ] })
          .eager(:head_pact_publications_for_tags)

        index_items = pact_publications.all.collect do | pact_publication |
          is_overall_latest_for_integration = latest_pp_ids.include?(pact_publication.id)

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
            consumer_version_tags(pact_publication, options[:tags]).sort_by(&:created_at).collect(&:name),
            options[:tags] && latest_verification ? latest_verification.provider_version.tags.select(&:latest_for_pacticipant?).sort_by(&:created_at) : [],
            pact_publication.latest_for_branch?
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
          pact_publication.head_pact_tags
        elsif tags_option.is_a?(Array)
          pact_publication.head_pact_tags.select{ |tag| tags_option.include?(tag.name)}
        else
          []
        end
      end

      def self.find_index_items_for_api(consumer_name: nil, provider_name: nil, **ignored)
        latest_pp_ids = latest_pact_publication_ids
        pact_publications = head_pact_publications(consumer_name: consumer_name, provider_name: provider_name, tags: true)
          .eager(:consumer)
          .eager(:provider)
          .eager(:pact_version)
          .eager(consumer_version: [:latest_version_for_branch, { tags: :head_tag }])
          .eager(latest_verification: { provider_version: [:latest_version_for_branch, { tags: :head_tag }]})
          .eager(:head_pact_publications_for_tags)

        pact_publications.all.collect do | pact_publication |
          is_overall_latest_for_integration = latest_pp_ids.include?(pact_publication.id)

          PactBroker::Domain::IndexItem.create(
            pact_publication.consumer,
            pact_publication.provider,
            pact_publication.to_domain_lightweight,
            is_overall_latest_for_integration,
            pact_publication.latest_verification,
            [],
            [],
            pact_publication.head_pact_tags.sort_by(&:created_at).collect(&:name),
            pact_publication.latest_verification ? pact_publication.latest_verification.provider_version.tags.select(&:latest_for_pacticipant?).sort_by(&:created_at) : []
          )
        end.sort
      end

      def self.latest_pact_publications
        PactBroker::Pacts::PactPublication.overall_latest
      end

      def self.latest_pact_publication_ids
        PactBroker::Pacts::PactPublication.select(Sequel[:pact_publications][:id]).overall_latest.collect(&:id)
      end

      def self.db
        PactBroker::Pacts::PactPublication.db
      end

      def self.head_pact_publications(options = {})
        base = PactBroker::Pacts::PactPublication.select(Sequel[:pact_publications][:id])

        if options[:consumer_name]
          consumer = pacticipant_repository.find_by_name!(options[:consumer_name])
          base = base.for_consumer(consumer)
        end

        if options[:provider_name]
          provider = pacticipant_repository.find_by_name!(options[:provider_name])
          base = base.for_provider(provider)
        end

        latest = base.overall_latest
        ids_query = if options[:tags].is_a?(Array)
          latest.union(base.latest_for_consumer_tag(options[:tags]))
        elsif options[:tags]
          latest.union(base.latest_by_consumer_tag)
        else
          latest
        end

        query = PactBroker::Pacts::PactPublication.select_all_qualified.where(Sequel[:pact_publications][:id] => ids_query)
          .join_consumers(:consumers)
          .join_providers(:providers)
          .join(:versions, { Sequel[:pact_publications][:consumer_version_id] => Sequel[:cv][:id] }, { table_alias: :cv } )

        order_columns = [
          Sequel.asc(Sequel.function(:lower, Sequel[:consumers][:name])),
          Sequel.desc(Sequel[:cv][:order]),
          Sequel.asc(Sequel.function(:lower, Sequel[:providers][:name]))
        ]

        query.order(*order_columns)
          .paginate(options[:page_number] || DEFAULT_PAGE_NUMBER, options[:page_size] || DEFAULT_PAGE_SIZE)
      end

      # eager loading the tag stuff doesn't seem to make it quicker
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
