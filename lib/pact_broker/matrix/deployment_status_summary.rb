require 'pact_broker/logging'

module PactBroker
  module Matrix
    class DeploymentStatusSummary
      include PactBroker::Logging

      attr_reader :rows, :resolved_selectors, :integrations

      def initialize(rows, resolved_selectors, integrations)
        @rows = rows
        @resolved_selectors = resolved_selectors
        @integrations = integrations
      end

      def counts
        {
          success: rows.count{ |row| row.success },
          failed: rows.count { |row| row.success == false },
          unknown: required_integrations_without_a_row.count + rows.count { |row| row.success.nil? }
        }
      end

      def deployable?
        return false if specified_selectors_that_do_not_exist.any?
        return nil if rows.any?{ |row| row.success.nil? }
        return nil if required_integrations_without_a_row.any?
        rows.all?{ |row| row.success } # true if rows is empty
      end

      def reasons
        error_messages.any? ? error_messages : success_messages
      end

      def error_messages
        @error_messages ||= begin
          messages = []
          messages.concat(specified_selectors_do_not_exist_messages)
          if messages.empty?
            messages.concat(missing_reasons)
            messages.concat(failure_messages)
            messages.concat(unverified_messages)
          end
          messages.uniq
        end
      end

      def specified_selectors_that_do_not_exist
        resolved_selectors.select(&:specified_version_that_does_not_exist?)
      end

      def specified_selectors_do_not_exist_messages
        specified_selectors_that_do_not_exist.collect(&:version_does_not_exist_description)
      end

      def unverified_messages
        if rows.any?{ |row| row.success.nil? }
          rows.collect do | row |
            missing_verified_pact_reason(row)

            # selectors = selectors_without_a_version_for(row)
            # if selectors.any?
            #   selectors.collect(&:version_does_not_exist_description)
            # else
            #   ["Missing one or more required verification results"]
            # end
          end
        else
          []
        end.flatten.uniq
      end

      def failure_messages
        if rows.any?{ |row| row.success == false }
          ["One or more verifications have failed"]
        else
          []
        end
      end

      def success_messages
        if rows.all?{ |row| row.success } && required_integrations_without_a_row.empty?
          if rows.any?
            ["All required verification results are published and successful"]
          else
            ["There are no missing dependencies"]
          end
        else
          []
        end.flatten.uniq
      end

      # For deployment, the consumer requires the provider,
      # but the provider does not require the consumer
      # This method tells us which providers are missing.
      def required_integrations_without_a_row
        @required_integrations_without_a_row ||= begin
          integrations.select(&:required?).select do | relationship |
            !rows.find do | row |
              row.consumer_id == relationship.consumer_id && row.provider_id == relationship.provider_id
            end
          end
        end
      end

      def missing_reasons
        required_integrations_without_a_row.collect do | integration |
          relevant_selectors_without_a_version = selectors_without_a_version_for(integration)
          # if relevant_selectors_without_a_version.any?
          #   missing_specified_version_reasons(relevant_selectors_without_a_version)
          # else
            missing_verified_pact_reason(integration)
          # end
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

      def missing_verified_pact_reason(integration)
        "There is no verified pact between #{description_for_selector(integration.consumer_name)} and #{description_for_selector(integration.provider_name)}"
        # "There is no verification by #{description_for_selector(integration.provider_name)} for the pact for #{description_for_selector(integration.consumer_name)}"
      end

      def description_for_selector(pacticipant_name)
        resolved_selector = resolved_selectors.find{ | s| s.pacticipant_name == pacticipant_name }
        if resolved_selector
          resolved_selector.description
        else
          # This happens when the user has not specified a version of the provider (eg no 'latest' and/or 'tag')
          # so the "add inferred selectors" code has not run
          # AND no versions of the provider exist (ie. it has never verified the pact).
          logger.warn "Could not find the resolved version for pacticipant_name #{pacticipant_name} from integrations #{integrations.collect(&:to_s).join(", ")} in resolved selectors #{resolved_selectors.inspect}"
          "#{pacticipant_name} (unresolved version)"
        end
      end
    end
  end
end
