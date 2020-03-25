require 'pact_broker/repositories/helpers'
require 'pact_broker/matrix/row'
require 'pact_broker/matrix/quick_row'
require 'pact_broker/matrix/every_row'
require 'pact_broker/matrix/head_row'
require 'pact_broker/error'
require 'pact_broker/matrix/query_results'
require 'pact_broker/matrix/integration'
require 'pact_broker/matrix/query_results_with_deployment_status_summary'
require 'pact_broker/matrix/resolved_selector'
require 'pact_broker/matrix/unresolved_selector'
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
        resolved_specified_selectors = resolve_versions_and_add_ids(specified_selectors, :specified)
        integrations = find_integrations_for_specified_selectors(resolved_specified_selectors, infer_selectors_for_integrations?(options))
        resolved_selectors = if infer_selectors_for_integrations?(options)
          resolved_specified_selectors + inferred_selectors(resolved_specified_selectors, integrations, options)
        else
          resolved_specified_selectors
        end

        all_lines = query_matrix(resolved_selectors, options)
        lines = apply_latestby(options, all_lines)

        # This needs to be done after the latestby, so can't be done in the db unless
        # the latestby logic is moved to the db
        if options.key?(:success)
          lines = lines.select{ |l| options[:success].include?(l.success) }
        end

        QueryResults.new(lines.sort, specified_selectors, options, resolved_selectors, integrations)
      end

      def find_for_consumer_and_provider pacticipant_1_name, pacticipant_2_name
        selectors = [ UnresolvedSelector.new(pacticipant_name: pacticipant_1_name), UnresolvedSelector.new(pacticipant_name: pacticipant_2_name)]
        options = { latestby: 'cvpv' }
        find(selectors, options)
      end

      def find_compatible_pacticipant_versions selectors
        find(selectors, latestby: 'cvpv').select(&:success)
      end

      def find_integrations_for_specified_selectors(resolved_specified_selectors, infer_integrations)
        specified_pacticipant_names = resolved_specified_selectors.collect(&:pacticipant_name)
        QuickRow
          .distinct_integrations(resolved_specified_selectors, infer_integrations)
          .collect(&:to_hash)
          .collect do | hash |
            required = is_a_row_for_this_integration_required?(specified_pacticipant_names, hash[:consumer_name])
            Integration.from_hash(hash.merge(required: required))
          end
      end

      private

      # If a specified pacticipant is a consumer, then its provider is required to be deployed
      # to the same environment before the consumer can be deployed.
      # If a specified pacticipant is a provider only, then it may be deployed
      # without the consumer being present.
      def is_a_row_for_this_integration_required?(specified_pacticipant_names, consumer_name)
        specified_pacticipant_names.include?(consumer_name)
      end

      # It would be nicer to do this in the SQL, but it requires time that I don't have at the moment
      def apply_latestby options, lines
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
          .collect{ | lines | lines.first.provider_version_number.nil? ? lines : lines.sort_by(&:provider_version_order).last }
          .flatten
      end

      def query_matrix selectors, options
        query = base_model(options).select_all_columns
                  .matching_selectors(selectors)
                  .order_by_last_action_date

        query = query.limit(options[:limit]) if options[:limit]
        query.eager_all_the_things.all
      end

      def base_model(options)
        options[:latestby] ? QuickRow : EveryRow
      end

      # Find the version number for selectors with the latest and/or tag specified
      def resolve_versions_and_add_ids(selectors, selector_type)
        selectors.collect do | selector |
          pacticipant = PactBroker::Domain::Pacticipant.find(name: selector.pacticipant_name)
          versions = find_versions_for_selector(selector)
          build_resolved_selectors(pacticipant, versions, selector, selector_type)
        end.flatten
      end

      def find_versions_for_selector(selector)
        # For selectors that just set the pacticipant name, there's no need to resolve the version -
        # only the pacticipant ID will be used in the query
        return nil unless (selector.tag || selector.latest || selector.pacticipant_version_number)

        versions = version_repository.find_versions_for_selector(selector)

        if selector.latest
          [versions.first]
        else
          versions.empty? ? [nil] : versions
        end
      end

      # When a single selector specifies multiple versions (eg. "all prod pacts"), this expands
      # the single selector into one selector for each version.
      def build_resolved_selectors(pacticipant, versions, original_selector, selector_type)
        if versions
          versions.collect do | version |
            if version
              selector_for_version(pacticipant, version, original_selector, selector_type)
            else
              selector_for_non_existing_version(pacticipant, original_selector, selector_type)
            end
          end
        else
          selector_without_version(pacticipant, selector_type)
        end
      end

      def infer_selectors_for_integrations?(options)
        options[:latest] || options[:tag]
      end

      # When only one selector is specified, (eg. checking to see if Foo version 2 can be deployed to prod),
      # need to look up all integrated pacticipants, and determine their relevant (eg. latest prod) versions
      def inferred_selectors(resolved_specified_selectors, integrations, options)
        all_pacticipant_names = integrations.collect(&:pacticipant_names).flatten.uniq
        specified_names = resolved_specified_selectors.collect{ |s| s[:pacticipant_name] }
        inferred_pacticipant_names = all_pacticipant_names - specified_names
        build_inferred_selectors(inferred_pacticipant_names, options)
      end

      def build_inferred_selectors(inferred_pacticipant_names, options)
        selectors = inferred_pacticipant_names.collect do | pacticipant_name |
          selector = UnresolvedSelector.new(pacticipant_name: pacticipant_name)
          selector.tag = options[:tag] if options[:tag]
          selector.latest = options[:latest] if options[:latest]
          selector
        end
        resolve_versions_and_add_ids(selectors, :inferred)
      end

      def selector_for_non_existing_version(pacticipant, original_selector, selector_type)
        ResolvedSelector.for_pacticipant_and_non_existing_version(pacticipant, original_selector, selector_type)
      end

      def selector_for_version(pacticipant, version, original_selector, selector_type)
        ResolvedSelector.for_pacticipant_and_version(pacticipant, version, original_selector, selector_type)
      end

      def selector_without_version(pacticipant, selector_type)
        ResolvedSelector.for_pacticipant(pacticipant, selector_type)
      end
    end
  end
end
