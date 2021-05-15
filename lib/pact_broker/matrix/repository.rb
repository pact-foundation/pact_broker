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
        resolved_ignore_selectors = resolve_ignore_selectors(options) # Naughty to modify the options hash! :shrug:
        resolved_specified_selectors = resolve_versions_and_add_ids(specified_selectors, :specified, resolved_ignore_selectors)
        integrations = find_integrations_for_specified_selectors(resolved_specified_selectors, infer_selectors_for_integrations?(options))
        resolved_selectors = add_any_inferred_selectors(resolved_specified_selectors, resolved_ignore_selectors, integrations, options)
        considered_rows, ignored_rows = find_considered_and_ignored_rows(resolved_selectors, resolved_ignore_selectors, options)
        QueryResults.new(considered_rows.sort, ignored_rows.sort, specified_selectors, options, resolved_selectors, resolved_ignore_selectors, integrations)
      end

      def find_for_consumer_and_provider pacticipant_1_name, pacticipant_2_name
        selectors = [ UnresolvedSelector.new(pacticipant_name: pacticipant_1_name), UnresolvedSelector.new(pacticipant_name: pacticipant_2_name)]
        options = { latestby: 'cvpv' }
        find(selectors, options)
      end

      private

      def find_considered_and_ignored_rows(resolved_selectors, resolved_ignore_selectors, options)
        rows = query_matrix(resolved_selectors, options)
        rows = apply_latestby(options, rows)
        rows = apply_success_filter(rows, options)
        considered_rows, ignored_rows = split_rows_into_considered_and_ignored(rows, resolved_ignore_selectors)
        return considered_rows, ignored_rows
      end

      def find_integrations_for_specified_selectors(resolved_specified_selectors, infer_integrations)
        specified_pacticipant_names = resolved_specified_selectors.collect(&:pacticipant_name)
        base_model_for_integrations
          .distinct_integrations(resolved_specified_selectors, infer_integrations)
          .collect(&:to_hash)
          .collect do | hash |
            required = is_a_row_for_this_integration_required?(specified_pacticipant_names, hash[:consumer_name])
            Integration.from_hash(hash.merge(required: required))
          end
      end

      def add_any_inferred_selectors(resolved_specified_selectors, resolved_ignore_selectors, integrations, options)
        if infer_selectors_for_integrations?(options)
          resolved_specified_selectors + inferred_selectors(resolved_specified_selectors, resolved_ignore_selectors, integrations, options)
        else
          resolved_specified_selectors
        end
      end

      def apply_success_filter(rows_with_latest_by_applied, options)
        # This needs to be done after the latestby, so can't be done in the db unless
        # the latestby logic is moved to the db
        if options.key?(:success)
           rows_with_latest_by_applied.select{ |l| options[:success].include?(l.success) }
         else
          rows_with_latest_by_applied
        end
      end

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

      def base_model(options = {})
        options[:latestby] ? QuickRow : EveryRow
      end

      def resolve_ignore_selectors(options)
        resolve_versions_and_add_ids(options.fetch(:ignore_selectors, []), :ignored)
      end

      # To make it easy for pf to override
      def base_model_for_integrations
        QuickRow
      end

      # Find the version number for selectors with the latest and/or tag specified
      def resolve_versions_and_add_ids(unresolved_selectors, selector_type, resolved_ignore_selectors = [])
        unresolved_selectors.collect do | unresolved_selector |
          pacticipant = PactBroker::Domain::Pacticipant.find(name: unresolved_selector.pacticipant_name)
          if pacticipant
            versions = find_versions_for_selector(unresolved_selector)
            build_resolved_selectors(pacticipant, versions, unresolved_selector, selector_type, resolved_ignore_selectors)
          else
            selector_for_non_existing_pacticipant(unresolved_selector, selector_type)
          end
        end.flatten
      end

      def find_versions_for_selector(selector)
        # For selectors that just set the pacticipant name, there's no need to resolve the version -
        # only the pacticipant ID will be used in the query
        return nil if selector.all_for_pacticipant?
        versions = version_repository.find_versions_for_selector(selector)

        if selector.latest
          [versions.first]
        else
          versions.empty? ? [nil] : versions
        end
      end

      # When a single selector specifies multiple versions (eg. "all prod pacts"), this expands
      # the single selector into one selector for each version.
      def build_resolved_selectors(pacticipant, versions, unresolved_selector, selector_type, resolved_ignore_selectors)
        if versions
          one_of_many = versions.compact.size > 1
          versions.collect do | version |
            if version
              selector_for_found_version(pacticipant, version, unresolved_selector, selector_type, one_of_many, resolved_ignore_selectors)
            else
              selector_for_non_existing_version(pacticipant, unresolved_selector, selector_type, resolved_ignore_selectors)
            end
          end
        else
          selector_for_all_versions_of_a_pacticipant(pacticipant, selector_type, resolved_ignore_selectors)
        end
      end

      def infer_selectors_for_integrations?(options)
        options[:latest] || options[:tag] || options[:branch] || options[:environment_name]
      end

      # When only one selector is specified, (eg. checking to see if Foo version 2 can be deployed to prod),
      # need to look up all integrated pacticipants, and determine their relevant (eg. latest prod) versions
      def inferred_selectors(resolved_specified_selectors, resolved_ignore_selectors, integrations, options)
        all_pacticipant_names = integrations.collect(&:pacticipant_names).flatten.uniq
        specified_names = resolved_specified_selectors.collect{ |s| s[:pacticipant_name] }
        inferred_pacticipant_names = all_pacticipant_names - specified_names
        build_inferred_selectors(inferred_pacticipant_names, resolved_ignore_selectors, options)
      end

      def build_inferred_selectors(inferred_pacticipant_names, resolved_ignore_selectors, options)
        selectors = inferred_pacticipant_names.collect do | pacticipant_name |
          selector = UnresolvedSelector.new(pacticipant_name: pacticipant_name)
          selector.tag = options[:tag] if options[:tag]
          selector.branch = options[:branch] if options[:branch]
          selector.latest = options[:latest] if options[:latest]
          selector.environment_name = options[:environment_name] if options[:environment_name]
          selector
        end
        resolve_versions_and_add_ids(selectors, :inferred, resolved_ignore_selectors)
      end

      def selector_for_non_existing_version(pacticipant, unresolved_selector, selector_type, resolved_ignore_selectors)
        ignore = resolved_ignore_selectors.any? do | s |
          s.pacticipant_id == pacticipant.id && s.only_pacticipant_name_specified?
        end
        ResolvedSelector.for_pacticipant_and_non_existing_version(pacticipant, unresolved_selector, selector_type, ignore)
      end

      def selector_for_found_version(pacticipant, version, unresolved_selector, selector_type, one_of_many, resolved_ignore_selectors)
        ignore = resolved_ignore_selectors.any? do | s |
          s.pacticipant_id == pacticipant.id && (s.only_pacticipant_name_specified? || s.pacticipant_version_id == version.id)
        end
        ResolvedSelector.for_pacticipant_and_version(pacticipant, version, unresolved_selector, selector_type, ignore, one_of_many)
      end

      def selector_for_all_versions_of_a_pacticipant(pacticipant, selector_type, resolved_ignore_selectors)
        # Doesn't make sense to ignore this, as you can't have a can-i-deploy query
        # for "all versions of a pacticipant". But whatever.
        ignore = resolved_ignore_selectors.any? do | s |
          s.pacticipant_id == pacticipant.id && s.only_pacticipant_name_specified?
        end
        ResolvedSelector.for_pacticipant(pacticipant, selector_type, ignore)
      end

      # only relevant for ignore selectors, validation stops this happening for the normal
      # selectors
      def selector_for_non_existing_pacticipant(unresolved_selector, selector_type)
        ResolvedSelector.for_non_existing_pacticipant(unresolved_selector, selector_type, false)
      end

      def split_rows_into_considered_and_ignored(rows, resolved_ignore_selectors)
        if resolved_ignore_selectors.any?
          considered, ignored = [], []
          rows.each do | row |
            if ignore_row?(resolved_ignore_selectors, row)
              ignored << row
            else
              considered << row
            end
          end
          return considered, ignored
        else
          return rows, []
        end
      end

      def ignore_row?(resolved_ignore_selectors, row)
        resolved_ignore_selectors.any? do | s |
          s.pacticipant_id == row.consumer_id  && (s.only_pacticipant_name_specified? || s.pacticipant_version_id == row.consumer_version_id) ||
            s.pacticipant_id == row.provider_id  && (s.only_pacticipant_name_specified? || s.pacticipant_version_id == row.provider_version_id)
        end
      end
    end
  end
end
