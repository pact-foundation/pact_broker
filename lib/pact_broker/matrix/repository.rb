require "pact_broker/matrix/matrix_row"
require "pact_broker/matrix/every_row"
require "pact_broker/matrix/query_results"
require "pact_broker/matrix/integration"
require "pact_broker/matrix/query_results_with_deployment_status_summary"
require "pact_broker/matrix/unresolved_selector"
require "pact_broker/verifications/latest_verification_id_for_pact_version_and_provider_version"
require "pact_broker/matrix/integrations_repository"
require "pact_broker/matrix/resolved_selectors_builder"
require "pact_broker/matrix/row_ignorer"
require "pact_broker/matrix/integrations_repository"

module PactBroker
  module Matrix
    class Repository
      include PactBroker::Repositories

      # Used when using table_print to output query results
      TP_COLS = [ :consumer_version_number, :pact_revision_number, :provider_version_number, :verification_number]

      GROUP_BY_PROVIDER_VERSION_NUMBER = [:consumer_name, :consumer_version_number, :provider_name, :provider_version_number]
      GROUP_BY_PROVIDER = [:consumer_name, :consumer_version_number, :provider_name]
      GROUP_BY_PACT = [:consumer_name, :provider_name]

      # THE METHOD for querying the Matrix
      # @param [Array<PactBroker::Matrix::UnresolvedSelector>] unresolved_specified_selectors
      # @param [Hash] options
      def find(unresolved_specified_selectors, options = {})
        infer_selectors = infer_selectors_for_integrations?(options)
        resolved_selectors_builder = ResolvedSelectorsBuilder.new
        resolved_selectors_builder.resolve_selectors(unresolved_specified_selectors, options.fetch(:ignore_selectors, []))
        integrations = matrix_integration_repository.find_integrations_for_specified_selectors(resolved_selectors_builder.specified_selectors, infer_selectors)
        resolved_selectors_builder.resolve_inferred_selectors(integrations, options) if infer_selectors

        considered_rows, ignored_rows = find_considered_and_ignored_rows(resolved_selectors_builder.all_selectors, resolved_selectors_builder.ignore_selectors, options)
        QueryResults.new(
          considered_rows.sort,
          ignored_rows.sort,
          unresolved_specified_selectors,
          options,
          resolved_selectors_builder.all_selectors,
          resolved_selectors_builder.ignore_selectors,
          integrations
        )
      end

      def find_for_consumer_and_provider(pacticipant_1_name, pacticipant_2_name)
        selectors = [ UnresolvedSelector.new(pacticipant_name: pacticipant_1_name), UnresolvedSelector.new(pacticipant_name: pacticipant_2_name)]
        options = { latestby: "cvpv" }
        find(selectors, options)
      end

      private

      def matrix_integration_repository
        PactBroker::Matrix::IntegrationsRepository.new
      end

      # If the user has specified --to TAG or --to-environment ENVIRONMENT in the CLI
      # (or nothing, which to defaults to latest=true - "with the latest version of the other integrated applications")
      # we need to work out what the integrations are between the specified selectors and the other pacticipant versions
      # in the target environment/branches/tags.
      # @param [Hash] options the matrix options
      # @return [Boolean]
      def infer_selectors_for_integrations?(options)
        options[:latest] || !!options[:tag] || !!options[:branch] || !!options[:environment_name] || options[:main_branch]
      end

      def find_considered_and_ignored_rows(all_resolved_selectors, resolved_ignore_selectors, options)
        rows = query_matrix(all_resolved_selectors, options)
        rows = apply_latestby(options, rows)
        rows = apply_success_filter(rows, options)
        considered_rows, ignored_rows = RowIgnorer.split_rows_into_considered_and_ignored(rows, resolved_ignore_selectors)
        return considered_rows, ignored_rows
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

      # rubocop: disable Metrics/CyclomaticComplexity
      # It would be nicer to do this in the SQL, but it requires time that I don't have at the moment
      def apply_latestby(options, lines)
        return lines unless options[:latestby]
        group_by_columns = case options[:latestby]
                           when "cvpv" then GROUP_BY_PROVIDER_VERSION_NUMBER
                           when "cvp" then GROUP_BY_PROVIDER
                           when "cp" then GROUP_BY_PACT
                           end

        # The group with the nil provider_version_numbers will be the results of the left outer join
        # that don't have verifications, so we need to include them all.
        lines.group_by{|line| group_by_columns.collect{|key| line.send(key) }}
          .values
          .collect{ | line | line.first.provider_version_number.nil? ? line : line.sort_by(&:provider_version_order).last }
          .flatten
      end
      # rubocop: enable Metrics/CyclomaticComplexity

      def query_matrix(all_resolved_selectors, options)
        query = base_model(options)
                  .matching_selectors(all_resolved_selectors)
                  .order_by_last_action_date

        query = query.limit(options[:limit]) if options[:limit]
        query.eager_all_the_things.all
      end

      def base_model(options = {})
        options[:latestby] ? MatrixRow : EveryRow
      end
    end
  end
end
