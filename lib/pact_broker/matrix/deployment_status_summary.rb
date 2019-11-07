require 'pact_broker/logging'
require 'pact_broker/matrix/reason'

module PactBroker
  module Matrix
    class DeploymentStatusSummary
      include PactBroker::Logging

      attr_reader :rows, :resolved_selectors, :integrations

      def initialize(rows, resolved_selectors, integrations)
        @rows = rows
        @resolved_selectors = resolved_selectors
        @integrations = integrations
        @dummy_selectors = create_dummy_selectors
      end

      def counts
        {
          success: rows.count(&:success),
          failed: rows.count { |row| row.success == false },
          unknown: required_integrations_without_a_row.count + rows.count { |row| row.success.nil? }
        }
      end

      def deployable?
        return false if specified_selectors_that_do_not_exist.any?
        return nil if rows.any?{ |row| row.success.nil? }
        return nil if required_integrations_without_a_row.any?
        rows.all?(&:success) # true if rows is empty
      end

      def reasons
        error_messages.any? ? error_messages : success_messages
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

      def specified_selectors_that_do_not_exist
        resolved_selectors.select(&:specified_version_that_does_not_exist?)
      end

      def specified_selectors_do_not_exist_messages
        specified_selectors_that_do_not_exist.collect do | selector |
          SpecifiedVersionDoesNotExist.new(selector)
        end
      end

      def not_ever_verified_reasons
        rows.select{ | row | row.success.nil? }.collect{ |row | pact_not_ever_verified_by_provider(row) }
      end

      def failure_messages
        rows.select{ |row| row.success == false }.collect do | row |
          VerificationFailed.new(*selectors_for(row))
        end
      end

      def success_messages
        if rows.all?(&:success) && required_integrations_without_a_row.empty?
          if rows.any?
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
      # No matrix rows would be returned. This method identifies that we have no row for
      # the Foo -> Bar integration, and therefore cannot deploy Foo.
      # However, if we were to try and deploy the provider, Bar, that would be ok
      # as Bar does not rely on Foo, so this method would not return that integration.
      def required_integrations_without_a_row
        @required_integrations_without_a_row ||= begin
          integrations.select(&:required?).select do | integration |
            !row_exists_for_integration(integration)
          end
        end
      end

      def row_exists_for_integration(integration)
        rows.find { | row | integration == row }
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

      # When the user has not specified a version of the provider (eg no 'latest' and/or 'tag')
      # so the "add inferred selectors" code in the Matrix::Repository has not run,
      # we may end up with rows for which we do not have a selector.
      # To solve this, create dummy selectors from the row and integration data.
      def create_dummy_selectors
        (dummy_selectors_from_rows + dummy_selectors_from_integrations).uniq
      end

      def dummy_selectors_from_integrations
        integrations.collect do | row |
          dummy_consumer_selector = ResolvedSelector.for_pacticipant(row.consumer, :inferred)
          dummy_provider_selector = ResolvedSelector.for_pacticipant(row.provider, :inferred)
          [dummy_consumer_selector, dummy_provider_selector]
        end.flatten
      end

      def dummy_selectors_from_rows
        rows.collect do | row |
          dummy_consumer_selector = ResolvedSelector.for_pacticipant_and_version(row.consumer, row.consumer_version, {}, :inferred)
          dummy_provider_selector = row.provider_version ?
            ResolvedSelector.for_pacticipant_and_version(row.provider, row.provider_version, {}, :inferred) :
            ResolvedSelector.for_pacticipant(row.provider, :inferred)
          [dummy_consumer_selector, dummy_provider_selector]
        end.flatten
      end
    end
  end
end
