require "pact_broker/repositories"
require "pact_broker/logging"
require "pact_broker/domain/index_item"
require "pact_broker/repositories/helpers"
require "pact_broker/index/page"
require "pact_broker/verifications/latest_verification_for_consumer_version_tag"
require "pact_broker/string_refinements"

module PactBroker
  module Index
    class Service
      extend PactBroker::Repositories
      extend PactBroker::Services
      extend PactBroker::Logging
      using PactBroker::StringRefinements

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

      def self.smart_default_view(consumer_name, provider_name)
        consumer = pacticipant_repository.find_by_name(consumer_name)
        provider = pacticipant_repository.find_by_name(provider_name)
        if consumer && provider
          pact_publications_with_branches = PactBroker::Pacts::PactPublication
                                            .for_consumer_name(consumer_name)
                                            .for_provider_name(provider_name)
                                            .join_consumer_branch_versions

          pact_publication_with_tags =   PactBroker::Pacts::PactPublication
            .for_consumer_name(consumer_name)
            .for_provider_name(provider_name)
            .join_consumer_version_tags

          if pact_publications_with_branches.any?
            "branch"
          elsif pact_publication_with_tags.any?
            "tag"
          else
            "all"
          end
        else
          nil
        end
      end

      # rubocop: disable Metrics/CyclomaticComplexity
      # rubocop: disable Metrics/MethodLength
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
          .eager(pact_version: { latest_verification: { provider_version: [{ current_deployed_versions: :environment }, { current_supported_released_versions: :environment }, :branch_heads, { tags: :head_tag } ] } })
          .eager(integration: [{latest_verification: :provider_version}, :latest_triggered_webhooks])
          .eager(consumer_version: [{ current_deployed_versions: :environment }, { current_supported_released_versions: :environment }, :branch_heads, { tags: :head_tag }])
          .eager(:head_pact_publications_for_tags)

        index_items = pact_publications.all.collect do | pact_publication |
          is_overall_latest_for_integration = latest_pp_ids.include?(pact_publication.id)

          latest_verification = latest_verification_for_pseudo_branch(pact_publication, is_overall_latest_for_integration, latest_verifications_for_cv_tags, options[:tags], options)
          webhook = webhooks.find{ |wh| wh.is_for?(pact_publication.integration) }

          PactBroker::Domain::IndexItem.create(
            pact_publication.consumer,
            pact_publication.provider,
            pact_publication.consumer_version,
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
      # rubocop: enable Metrics/MethodLength
      # rubocop: enable Metrics/CyclomaticComplexity

      # Worst. Code. Ever.
      # This needs a big rethink.
      # TODO environments view
      # rubocop: disable Metrics/CyclomaticComplexity
      def self.latest_verification_for_pseudo_branch(pact_publication, is_overall_latest, latest_verifications_for_cv_tags, tags_option, options)
        if options[:view] == "branch" || (options[:view] == "all" && pact_publication.consumer_version.branch_heads.any?)
          pact_publication.latest_verification || pact_publication.latest_verification_for_consumer_branches
        elsif tags_option == true
          latest_verifications_for_cv_tags
            .select{ | v | v.consumer_id == pact_publication.consumer_id && v.provider_id == pact_publication.provider_id && pact_publication.head_pact_tags.collect(&:name).include?(v.consumer_version_tag_name) }
            .sort{ |v1, v2| v1.id <=> v2.id }.last || (is_overall_latest ? pact_publication.integration.latest_verification : nil)
        elsif tags_option.is_a?(Array)
          latest_verifications_for_cv_tags
          .select{ | v | v.consumer_id == pact_publication.consumer_id && v.provider_id == pact_publication.provider_id && pact_publication.head_pact_tags.collect(&:name).include?(v.consumer_version_tag_name) && tags_option.include?(v.consumer_version_tag_name) }
          .sort{ |v1, v2| v1.id <=> v2.id }.last  || (is_overall_latest ? pact_publication.integration.latest_verification : nil)
        else
          pact_publication.integration.latest_verification
        end
      end
      # rubocop: enable Metrics/CyclomaticComplexity

      def self.consumer_version_tags(pact_publication, tags_option)
        if tags_option == true
          pact_publication.head_pact_tags
        elsif tags_option.is_a?(Array)
          pact_publication.head_pact_tags.select{ |tag| tags_option.include?(tag.name)}
        else
          []
        end
      end

      def self.find_index_items_for_api(consumer_name: nil, provider_name: nil, page_number: nil, page_size: nil, **_ignored)
        latest_pp_ids = latest_pact_publication_ids
        pact_publications = head_pact_publications(consumer_name: consumer_name, provider_name: provider_name, tags: true, page_number: page_number, page_size: page_size)
          .eager(:consumer)
          .eager(:provider)
          .eager(pact_version: { latest_verification: { provider_version: [{ current_deployed_versions: :environment }, { current_supported_released_versions: :environment }, { branch_heads: :branch_version }, { tags: :head_tag }]} })
          .eager(consumer_version: [{ current_deployed_versions: :environment }, { current_supported_released_versions: :environment }, { branch_heads: :branch_version }, { tags: :head_tag }])
          .eager(:head_pact_publications_for_tags)

        pact_publications.all.collect do | pact_publication |
          is_overall_latest_for_integration = latest_pp_ids.include?(pact_publication.id)

          PactBroker::Domain::IndexItem.create(
            pact_publication.consumer,
            pact_publication.provider,
            pact_publication.consumer_version,
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
        base = base_query(options)

        if options[:search]
          pacticipant_ids = pact_pacticipant_ids_by_name(options[:search])
          base = base.where(Sequel.|(
            { Sequel[:pact_publications][:consumer_id] => pacticipant_ids },
            { Sequel[:pact_publications][:provider_id] => pacticipant_ids }
          ))

          # Return early if there is no pacticipant matches the input name
          return base.paginate(options[:page_number] || DEFAULT_PAGE_NUMBER, options[:page_size] || DEFAULT_PAGE_SIZE) if pacticipant_ids.empty?
        end

        ids_query = if options[:view]
                      pact_publications_by_view(base, options)
                    else
                      query_pact_publication_ids_by_tags(base, options[:tags])
                    end

        select_columns_and_order(ids_query, options)
      end

      def self.pact_publications_by_view(query, options)
        case options[:view]
        when "branch" then query.latest_by_consumer_branch
        when "tag" then query.latest_by_consumer_tag
        when "environment" then query.in_environments
        else
          query
            .overall_latest
            .union(query.latest_by_consumer_branch)
            .union(query.latest_by_consumer_tag)
            .union(query.in_environments)
        end
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
            .eager(provider_version: [{ current_deployed_versions: :environment }, { current_supported_released_versions: :environment }])
            .all
        else
          nil # should not be used
        end
      end

      def self.query_pact_publication_ids_by_tags(base, tags)
        latest = base.overall_latest
        return latest.union(base.latest_for_consumer_tag(tags)) if tags.is_a?(Array)
        return latest.union(base.latest_by_consumer_tag).union(base.for_environment(nil)) if tags
        latest
      end

      def self.base_query(options)
        query = PactBroker::Pacts::PactPublication.select(Sequel[:pact_publications][:id])

        if options[:consumer_name]
          consumer = pacticipant_repository.find_by_name!(options[:consumer_name])
          query = query.for_consumer(consumer)
        end

        if options[:provider_name]
          provider = pacticipant_repository.find_by_name!(options[:provider_name])
          query = query.for_provider(provider)
        end

        query
      end


      def self.pact_pacticipant_ids_by_name(pacticipant_name)
        pacticipant_repository.search_by_name(pacticipant_name).collect(&:id)
      end

      def self.select_columns_and_order(ids_query, options)
        query = PactBroker::Pacts::PactPublication
                  .select_all_qualified
                  .where(Sequel[:pact_publications][:id] => ids_query)
                  .join_consumers(:consumers)
                  .join_providers(:providers)


        order_columns = [
          Sequel.asc(Sequel.function(:lower, Sequel[:consumers][:name])),
          Sequel.desc(Sequel[:pact_publications][:consumer_version_order]),
          Sequel.asc(Sequel.function(:lower, Sequel[:providers][:name]))
        ]

        pact_number = options[:page_number] || DEFAULT_PAGE_NUMBER
        page_size = options[:page_size] || DEFAULT_PAGE_SIZE

        query.order(*order_columns).paginate(pact_number, page_size)
      end

      private_class_method :base_query, :query_pact_publication_ids_by_tags, :pact_pacticipant_ids_by_name, :select_columns_and_order
    end
  end
end
