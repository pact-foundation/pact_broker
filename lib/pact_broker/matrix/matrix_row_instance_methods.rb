# The instance methods
module PactBroker
  module Matrix
    module MatrixRowInstanceMethods
      def pact_version_sha
        pact_version.sha
      end

      def pact_revision_number
        pact_publication.revision_number
      end

      def verification_number
        verification&.number
      end

      def success
        verification&.success
      end

      def pact_created_at
        pact_publication.created_at
      end

      def verification_executed_at
        verification&.execution_date
      end

      # Add logic for ignoring case
      def <=> other
        comparisons = [
          compare_name_asc(consumer_name, other.consumer_name),
          compare_number_desc(consumer_version_order, other.consumer_version_order),
          compare_number_desc(pact_revision_number, other.pact_revision_number),
          compare_name_asc(provider_name, other.provider_name),
          compare_number_desc(provider_version_order, other.provider_version_order),
          compare_number_desc(verification_id, other.verification_id)
        ]

        comparisons.find{|c| c != 0 } || 0
      end

      def compare_name_asc name1, name2
        name1 <=> name2
      end

      def to_s
        "#{consumer_name} v#{consumer_version_number} #{provider_name} #{provider_version_number} #{success}"
      end

      def compare_number_desc number1, number2
        if number1 && number2
          number2 <=> number1
        elsif number1
          1
        else
          -1
        end
      end

      def eql?(obj)
        (obj.class == model) && (obj.values == values)
      end

      def pacticipant_names
        [consumer_name, provider_name]
      end

      def involves_pacticipant_with_name?(pacticipant_name)
        pacticipant_name.include?(pacticipant_name)
      end

      def provider_version_id
        # null when not verified
        values[:provider_version_id]
      end

      def verification_id
        # null when not verified
        return_or_raise_if_not_set(:verification_id)
      end

      def consumer_name
        consumer.name
      end

      def consumer_version_number
        consumer_version.number
      end

      def consumer_version_branch_versions
        consumer_version.branch_versions
      end

      def consumer_version_deployed_versions
        consumer_version.current_deployed_versions
      end

      def consumer_version_released_versions
        consumer_version.current_supported_released_versions
      end

      def consumer_version_order
        consumer_version.order
      end

      def provider_name
        provider.name
      end

      def provider_version_number
        provider_version&.number
      end

      def provider_version_branch_versions
        provider_version&.branch_versions || []
      end

      def provider_version_deployed_versions
        provider_version&.current_deployed_versions || []
      end

      def provider_version_released_versions
        provider_version&.current_supported_released_versions || []
      end

      def provider_version_order
        provider_version&.order
      end

      def last_action_date
        return_or_raise_if_not_set(:last_action_date)
      end

      def has_verification?
        !!verification_id
      end

      # This model needs the verifications and pacticipants joined to it
      # before it can be used, as it's not a "real" model.
      def return_or_raise_if_not_set(key)
        if values.key?(key)
          values[key]
        else
          raise "Required table not joined"
        end
      end
    end
  end
end
