require 'pact_broker/repositories/helpers'
require 'pact_broker/matrix/row'
require 'pact_broker/matrix/head_row'
require 'pact_broker/error'
require 'pact_broker/matrix/query_results'
require 'pact_broker/matrix/integration'
require 'pact_broker/matrix/query_results_with_deployment_status_summary'
require 'pact_broker/matrix/resolved_selector'
require 'pact_broker/verifications/latest_verification_id_for_pact_version_and_provider_version'
require 'pact_broker/pacts/latest_pact_publications_by_consumer_version'

module PactBroker
  module Matrix

    class Error < PactBroker::Error; end

    class Repository
      include PactBroker::Repositories::Helpers
      include PactBroker::Repositories

      # TODO move latest verification logic in to database

      TP_COLS = PactBroker::Matrix::Row::TP_COLS

      GROUP_BY_PROVIDER_VERSION_NUMBER = [:consumer_name, :consumer_version_number, :provider_name, :provider_version_number]
      GROUP_BY_PROVIDER = [:consumer_name, :consumer_version_number, :provider_name]
      GROUP_BY_PACT = [:consumer_name, :provider_name]

      def find_ids_for_pacticipant_names params
        criteria  = {}

        if params[:consumer_name] || params[:provider_name]
          if params[:consumer_name]
            pacticipant = PactBroker::Domain::Pacticipant.where(name_like(:name, params[:consumer_name])).single_record
            criteria[:consumer_id] = pacticipant.id if pacticipant
          end

          if params[:provider_name]
            pacticipant = PactBroker::Domain::Pacticipant.where(name_like(:name, params[:provider_name])).single_record
            criteria[:provider_id] = pacticipant.id if pacticipant
          end
        end

        if params[:pacticipant_name]
          pacticipant = PactBroker::Domain::Pacticipant.where(name_like(:name, params[:pacticipant_name])).single_record
          criteria[:pacticipant_id] = pacticipant.id if pacticipant
        end

        criteria[:tag_name] = params[:tag_name] if params[:tag_name].is_a?(String) # Could be a sym from resource parameters in api.rb
        criteria
      end

      # Return the latest matrix row (pact/verification) for each consumer_version_number/provider_version_number
      def find specified_selectors, options = {}
        resolved_selectors = resolve_selectors(specified_selectors, options)
        lines = query_matrix(resolved_selectors, options)
        lines = apply_latestby(options, specified_selectors, lines)

        # This needs to be done after the latestby, so can't be done in the db unless
        # the latestby logic is moved to the db
        if options.key?(:success)
          lines = lines.select{ |l| options[:success].include?(l.success) }
        end

        integrations = find_integrations_for_specified_selectors(resolved_selectors.select(&:specified?))
        QueryResults.new(lines.sort, specified_selectors, options, resolved_selectors, integrations)
      end

      def find_for_consumer_and_provider pacticipant_1_name, pacticipant_2_name
        selectors = [{ pacticipant_name: pacticipant_1_name }, { pacticipant_name: pacticipant_2_name }]
        options = { latestby: 'cvpv' }
        find(selectors, options)
      end

      def find_compatible_pacticipant_versions selectors
        find(selectors, latestby: 'cvpv').select{|line| line.success }
      end

      # If one pacticipant is specified, find all the integrations that involve that pacticipant
      # If two or more are specified, just return the integrations that involve the specified pacticipants
      def find_integrations_for_specified_selectors(resolved_specified_selectors)
        specified_pacticipant_names = resolved_specified_selectors.collect(&:pacticipant_name)
        Row
          .select(:consumer_name, :consumer_id, :provider_name, :provider_id)
          .matching_selectors(resolved_specified_selectors)
          .distinct
          .all
          .collect do |row |
            row.to_hash
          end
          .uniq
          .collect do | hash |
            required = is_a_row_for_this_integration_required?(specified_pacticipant_names, hash[:consumer_name])
            Integration.from_hash(hash.merge(required: required))
          end
      end

      private

      # If one of the specified pacticipants is a consumer, then that provider is required to be deployed
      # to the same environment before the consumer can be deployed.
      # If one of the specified pacticipants is a provider, then the provider may be deployed
      # without the consumer being present.
      def is_a_row_for_this_integration_required?(specified_pacticipant_names, consumer_name)
        specified_pacticipant_names.include?(consumer_name)
      end

      # It would be nicer to do this in the SQL, but it requires time that I don't have at the moment
      def apply_latestby options, selectors, lines
        return lines unless options[:latestby]
        group_by_columns = case options[:latestby]
        when 'cvpv' then GROUP_BY_PROVIDER_VERSION_NUMBER
        when 'cvp' then GROUP_BY_PROVIDER
        when 'cp' then GROUP_BY_PACT
        end

        # The group with the nil provider_version_numbers will be the results of the left outer join
        # that don't have verifications, so we need to include them all.
        lines.group_by{|line| group_by_columns.collect{|key| line.send(key) }}
          .values
          .collect{ | lines | lines.first.provider_version_number.nil? ? lines : lines.first }
          .flatten
      end

      def query_matrix selectors, options
        query = Row
        if options[:latestby]
          query = query.where(pact_publication_id: Row.db[:latest_pact_publication_ids_for_consumer_versions].select(:pact_publication_id))
        end

        query = query.select_all.matching_selectors(selectors)

        query = query.limit(options[:limit]) if options[:limit]
        query
          .order_by_names_ascending_most_recent_first
          .eager(:consumer_version_tags)
          .eager(:provider_version_tags)
          .all
      end

      def resolve_selectors(specified_selectors, options)
        resolved_specified_selectors = resolve_versions_and_add_ids(specified_selectors, :specified, options[:latestby])
        if options[:latest] || options[:tag]
          add_inferred_selectors(resolved_specified_selectors, options)
        else
          resolved_specified_selectors
        end
      end

      # Find the version number for selectors with the latest and/or tag specified
      def resolve_versions_and_add_ids(selectors, selector_type, latestby)
        selectors.collect do | selector |
          pacticipant = PactBroker::Domain::Pacticipant.find(name: selector[:pacticipant_name])
          versions = find_versions_for_selector(selector)
          build_selectors_for_pacticipant_and_versions(pacticipant, versions, selector, selector_type, latestby)
        end.flatten
      end

      def build_selectors_for_pacticipant_and_versions(pacticipant, versions, original_selector, selector_type, latestby)
        if versions
          versions.collect do | version |
            if version
              selector_for_version(pacticipant, version, original_selector, selector_type, latestby)
            else
              selector_for_non_existing_version(pacticipant, original_selector, selector_type)
            end
          end
        else
          selector_without_version(pacticipant, selector_type)
        end
      end

      def find_versions_for_selector(selector)
        if selector[:tag] && selector[:latest]
          version = version_repository.find_by_pacticipant_name_and_latest_tag(selector[:pacticipant_name], selector[:tag])
          [version]
        elsif selector[:latest]
          version = version_repository.find_latest_by_pacticpant_name(selector[:pacticipant_name])
          [version]
        elsif selector[:tag]
          versions = version_repository.find_by_pacticipant_name_and_tag(selector[:pacticipant_name], selector[:tag])
          versions.any? ? versions : [nil]
        elsif selector[:pacticipant_version_number]
          version = version_repository.find_by_pacticipant_name_and_number(selector[:pacticipant_name], selector[:pacticipant_version_number])
          [version]
        else
          nil
        end
      end

      # When only one selector is specified, (eg. checking to see if Foo version 2 can be deployed to prod),
      # need to look up all integrated pacticipants, and determine their relevant (eg. latest prod) versions
      def add_inferred_selectors(resolved_specified_selectors, options)
        integrations = find_integrations_for_specified_selectors(resolved_specified_selectors)
        all_pacticipant_names = integrations.collect(&:pacticipant_names).flatten.uniq
        specified_names = resolved_specified_selectors.collect{ |s| s[:pacticipant_name] }
        inferred_pacticipant_names = all_pacticipant_names - specified_names
        resolved_specified_selectors + build_inferred_selectors(inferred_pacticipant_names, options)
      end

      def build_inferred_selectors(inferred_pacticipant_names, options)
        selectors = inferred_pacticipant_names.collect do | pacticipant_name |
          selector = {
            pacticipant_name: pacticipant_name
          }
          selector[:tag] = options[:tag] if options[:tag]
          selector[:latest] = options[:latest] if options[:latest]
          selector
        end
        resolve_versions_and_add_ids(selectors, :inferred, options[:latestby])
      end

      def all_pacticipant_names_in_specified_matrix(selectors)
        find_integrations_for_specified_selectors(selectors)
          .collect(&:pacticipant_names)
          .flatten
          .uniq
      end

      def selector_for_non_existing_version(pacticipant, original_selector, selector_type)
        ResolvedSelector.for_pacticipant_and_non_existing_version(pacticipant, original_selector, selector_type)
      end

      def selector_for_version(pacticipant, version, original_selector, selector_type, latestby)
        pact_publication_ids, verification_ids = nil, nil

        # Querying for the "pre-filtered" pact publications and verifications directly, rather than just using the consumer
        # and provider versions allows us to remove the "overwritten" pact revisions and verifications from the
        # matrix result set, making the final matrix query more efficient and stopping the query limit from
        # removing relevant data (eg. https://github.com/pact-foundation/pact_broker-client/issues/53)
        if latestby
          pact_publication_ids = PactBroker::Pacts::LatestPactPublicationsByConsumerVersion
                                            .select(:id)
                                            .where(consumer_version_id: version.id)
                                            .collect{ |pact_publication| pact_publication[:id] }

          verification_ids = PactBroker::Verifications::LatestVerificationIdForPactVersionAndProviderVersion
                                .select(:verification_id)
                                .distinct
                                .where(provider_version_id: version.id)
                                .collect{ |pact_publication| pact_publication[:verification_id] }
        end

        ResolvedSelector.for_pacticipant_and_version(pacticipant, version, pact_publication_ids, verification_ids, original_selector, selector_type)
      end

      def selector_without_version(pacticipant, selector_type)
        ResolvedSelector.for_pacticipant(pacticipant, selector_type)
      end
    end
  end
end
