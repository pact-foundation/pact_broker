require 'pact_broker/logging'
require 'pact_broker/matrix/reason'
require 'forwardable'

module PactBroker
  module Matrix
    class DeploymentStatusSummary
      include PactBroker::Logging
      extend Forwardable

      attr_reader :query_results, :all_rows
      delegate [:considered_rows, :ignored_rows, :resolved_selectors, :resolved_ignore_selectors, :integrations] => :query_results

      def initialize(query_results)
        @query_results = query_results
        @all_rows = query_results.rows
        @dummy_selectors = create_dummy_selectors
      end

      def counts
        {
          success: considered_rows.count(&:success),
          failed: considered_rows.count { |row| row.success == false },
          unknown: required_integrations_without_a_row.count + considered_rows.count { |row| row.success.nil? },
          ignored: resolved_ignore_selectors.any? ? ignored_rows.count : nil
        }.compact
      end

      def deployable?
        return false if considered_specified_selectors_that_do_not_exist.any?
        return nil if considered_rows.any?{ |row| row.success.nil? }
        return nil if required_integrations_without_a_row.any?
        considered_rows.all?(&:success) # true if considered_rows is empty
      end

      def reasons
        error_messages.any? ? warning_messages + error_messages  : warning_messages + success_messages
      end

      private

      attr_reader :dummy_selectors

      def error_messages
        @error_messages ||= begin
          messages = []
          messages.concat(specified_selectors_do_not_exist_messages)
          if messages.empty?
            messages.concat(missing_reasons)
            messages.concat(failure_messages)
            messages.concat(not_ever_verified_reasons)
          end
          messages.uniq
        end
      end

      def warning_messages
        resolved_ignore_selectors.select(&:pacticipant_or_version_does_not_exist?).collect { | s | IgnoreSelectorDoesNotExist.new(s) }
          # ignored_rows.select{ | row | row.success.nil? }.collect{ |row | IgnoredReason.new(pact_not_ever_verified_by_provider(row)) } +
          # specified_selectors_that_do_not_exist.select(&:ignore?).collect { | selector | IgnoredReason.new(SpecifiedVersionDoesNotExist.new(selector)) } +
          # ignored_rows.select{ |row| row.success == false }.collect { | row | IgnoredReason.new(VerificationFailed.new(*selectors_for(row))) }
      end

      def considered_specified_selectors_that_do_not_exist
        resolved_selectors.select(&:consider?).select(&:specified_version_that_does_not_exist?)
      end

      def specified_selectors_that_do_not_exist
        resolved_selectors.select(&:specified_version_that_does_not_exist?)
      end

      def specified_selectors_do_not_exist_messages
        specified_selectors_that_do_not_exist.select(&:consider?).collect { | selector | SpecifiedVersionDoesNotExist.new(selector) }
      end

      def not_ever_verified_reasons
        considered_rows.select{ | row | row.success.nil? }.collect{ |row | pact_not_ever_verified_by_provider(row) }
      end

      def failure_messages
        considered_rows.select{ |row| row.success == false }.collect { | row | VerificationFailed.new(*selectors_for(row)) }
      end

      def success_messages
        if considered_rows.all?(&:success) && required_integrations_without_a_row.empty?
          if considered_rows.any?
            [Successful.new]
          else
            [NoDependenciesMissing.new]
          end
        else
          []
        end.flatten.uniq
      end

      # For deployment, the consumer requires the provider,
      # but the provider does not require the consumer
      # This method tells us which providers are missing.
      # Technically, it tells us which integrations do not have a row
      # because the pact that belongs to the consumer version has
      # in fact been verified, but not by the provider version specified
      # in the query (because left outer join)
      #
      # Imagine query for deploying Foo v3 to prod with the following matrix:
      # Foo v2 -> Bar v1 (latest prod) [this line not included because CV doesn't match]
      # Foo v3 -> Bar v2               [this line not included because PV doesn't match]
      #
      # No matrix considered_rows would be returned. This method identifies that we have no row for
      # the Foo -> Bar integration, and therefore cannot deploy Foo.
      # However, if we were to try and deploy the provider, Bar, that would be ok
      # as Bar does not rely on Foo, so this method would not return that integration.
      # UPDATE:
      # The matrix query now returns a row with blank provider version/verification fields
      # so the above comment is now redundant.
      # I'm not sure if this piece of code can ever return a list with anything in it any more.
      # Will log it for a while and see.
      def required_integrations_without_a_row
        @required_integrations_without_a_row ||= begin
          integrations.select(&:required?).select do | integration |
            !row_exists_for_integration(integration)
          end
        end.tap { |it| log_required_integrations_without_a_row_occurred(it) if it.any? }
      end

      def log_required_integrations_without_a_row_occurred integrations
        logger.info("required_integrations_without_a_row returned non empty", payload: { integrations: integrations, considered_rows: considered_rows })
      end

      def row_exists_for_integration(integration)
        all_rows.find { | row | integration.matches_pacticipant_ids?(row) }
      end

      def missing_reasons
        required_integrations_without_a_row.collect do | integration |
          pact_not_verified_by_required_provider_version(integration)
        end.flatten
      end

      def selectors_without_a_version_for(integration)
        selectors_with_non_existing_versions.select do | selector |
          integration.involves_pacticipant_with_name?(selector.pacticipant_name)
        end
      end

      def selectors_with_non_existing_versions
        @selectors_with_non_existing_versions ||= resolved_selectors.select(&:latest_tagged_version_that_does_not_exist?)
      end

      def missing_specified_version_reasons(selectors)
        selectors.collect(&:version_does_not_exist_description)
      end

      def pact_not_verified_by_required_provider_version(integration)
        PactNotVerifiedByRequiredProviderVersion.new(*selectors_for(integration))
      end

      def pact_not_ever_verified_by_provider(row)
        PactNotEverVerifiedByProvider.new(*selectors_for(row))
      end

      def selector_for(pacticipant_name)
        resolved_selectors.find{ | s| s.pacticipant_name == pacticipant_name } ||
          dummy_selectors.find{ | s| s.pacticipant_name == pacticipant_name }
      end

      def selectors_for(row)
        [selector_for(row.consumer_name), selector_for(row.provider_name)]
      end

      # When the user has not specified a version of the provider (eg no 'latest' and/or 'tag', which means 'all versions')
      # so the "add inferred selectors" code in the Matrix::Repository has not run,
      # we may end up with considered_rows for which we do not have a selector.
      # To solve this, create dummy selectors from the row and integration data.
      def create_dummy_selectors
        (dummy_selectors_from_considered_rows + dummy_selectors_from_integrations).uniq
      end

      def dummy_selectors_from_integrations
        integrations.collect do | row |
          dummy_consumer_selector = ResolvedSelector.for_pacticipant(row.consumer, :inferred, false)
          dummy_provider_selector = ResolvedSelector.for_pacticipant(row.provider, :inferred, false)
          [dummy_consumer_selector, dummy_provider_selector]
        end.flatten
      end

      def dummy_selectors_from_considered_rows
        considered_rows.collect do | row |
          dummy_consumer_selector = ResolvedSelector.for_pacticipant_and_version(row.consumer, row.consumer_version, {}, :inferred, false)
          dummy_provider_selector = row.provider_version ?
            ResolvedSelector.for_pacticipant_and_version(row.provider, row.provider_version, {}, :inferred, false) :
            ResolvedSelector.for_pacticipant(row.provider, :inferred, false)
          [dummy_consumer_selector, dummy_provider_selector]
        end.flatten
      end

      # experimental
      def warnings_for_missing_interactions
        considered_rows.select(&:success).collect do | row |
          begin
            if row.verification.interactions_missing_test_results.any? && !row.verification.all_interactions_missing_test_results?
              InteractionsMissingVerifications.new(selector_for(row.consumer_name), selector_for(row.provider_name), row.verification.interactions_missing_test_results)
            end
          rescue StandardError => e
            logger.warn("Error determining if there were missing interaction verifications", e)
            nil
          end
        end.compact.tap { |it| report_missing_interaction_verifications(it) if it.any? }
      end

      def report_missing_interaction_verifications(messages)
        logger.warn("Interactions missing verifications", messages)
      end
    end
  end
end
