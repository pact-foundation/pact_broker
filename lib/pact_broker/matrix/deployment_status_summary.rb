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
        # return nil if rows.empty?
        return nil if rows.any?{ |row| row.success.nil? }
        return nil if required_integrations_without_a_row.any?
        rows.all?{ |row| row.success }
      end

      def reasons
        @reasons ||= begin
          reasons = []
          reasons.concat(missing_reasons)
          reasons.concat(failure_messages)
          reasons.concat(unverified_messages)
          reasons.concat(success_messages)
          reasons
        end
      end

      def unverified_messages
        if rows.any?{ |row| row.success.nil? }
          ["Missing one or more verification results"]
        else
          []
        end
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
          ["All verification results are published and successful"]
        else
          []
        end
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
        required_integrations_without_a_row.collect do | missing_relationship|
          consumer_version_desc = "#{missing_relationship.consumer_name} (#{resolved_version_for(missing_relationship.consumer_id)})"
          provider_version_desc = "#{missing_relationship.provider_name} (#{resolved_version_for(missing_relationship.provider_id)})"
          "There is no verified pact between #{consumer_version_desc} and #{provider_version_desc}"
        end
      end

      def resolved_version_for(pacticipant_id)
        resolved_selector = resolved_selectors.find{ | s| s[:pacticipant_id] == pacticipant_id }
        if resolved_selector
          resolved_selector[:pacticipant_version_number]
        else
          logger.warn "Could not find the resolved version for pacticipant_id #{pacticipant_id} from integrations #{integrations.collect(&:to_s).join(", ")} in resolved selectors #{resolved_selectors.inspect}"
          "unresolved version"
        end
      end
    end
  end
end
