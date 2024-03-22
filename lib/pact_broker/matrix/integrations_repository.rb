require "pact_broker/matrix/integration_row"
# A "find only" repository for the PactBroker::Matrix::Integration object.
# The PactBroker::Matrix::Integration object is not a Sequel Model like the PactBroker::Integrations::Integration - it is built from the
# matrix data specifically for a given matrix query, and as well as the consumer/provider attributes, it also
# knows whether or not that particular depdency is required in the context of the specific matrix query.
# eg. a HTTP consumer will always require that a provider is deployed, but a provider can be deployed if the consumer does not exist
# in the given environment yet.
# The "integrations for selectors" query is used to work out what what integrations are involved for a can-i-deploy query.

module PactBroker
  module Matrix
    class IntegrationsRepository
      # Find all the Integrations required for this query, using the options to determine whether to find
      # the inferred integrations or not.
      # The infer_selectors_for_integrations only makes a difference when there are multiple selectors.
      # When it is false, then only integrations are returned that exist *between* the versions of
      # the selectors. When it is true, then all integrations that involve any of the versions of the selectors
      # are returned.
      #
      # eg.
      # Foo v1 has verified contract with Bar v2
      # Waffle v3 has verified contract with Bar v2
      # Foo v1 has unverified contract with Frog
      #
      # With selectors Foo v1 and Bar v2, and infer_selectors_for_integrations false, the returned integrations are Foo/Bar
      # With the same selectors and infer_selectors_for_integrations true, the returned integrations are Foo/Bar, Waffle/Bar and Foo/Frog.
      #
      # When there is a single selector, the result is exactly the same whether infer_selectors_for_integrations is true or false.
      #
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_specified_selectors
      # @param [Boolean] infer_selectors_for_integrations
      # @return [Array<PactBroker::Matrix::Integration>]
      def find_integrations_for_specified_selectors(resolved_specified_selectors, infer_selectors_for_integrations)
        if infer_selectors_for_integrations || resolved_specified_selectors.size == 1
          find_integrations_involving_any_specfied_selectors(resolved_specified_selectors).sort_by(&:pacticipant_names)
        else
          find_integrations_between_specified_selectors(resolved_specified_selectors).sort_by(&:pacticipant_names)
        end
      end

      private

      # Find the Integrations that only involve the versions from the selectors specifed in the query.
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_specified_selectors
      # @return [Array<PactBroker::Matrix::Integration>]
      def find_integrations_between_specified_selectors(resolved_specified_selectors)
        specified_pacticipant_names = resolved_specified_selectors.collect(&:pacticipant_name)
        IntegrationRow
          .distinct_integrations_between_given_selectors(resolved_specified_selectors)
          .all
          .collect(&:to_hash)
          .collect do | integration_hash |
            required = is_a_row_for_this_integration_required?(specified_pacticipant_names, integration_hash[:consumer_name])
            Integration.from_hash(integration_hash.merge(required: required))
          end
      end

      # Find all Integrations where any of the specified selectors are involved.
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] resolved_specified_selectors
      # @return [Array<PactBroker::Matrix::Integration>]
      def find_integrations_involving_any_specfied_selectors(resolved_specified_selectors)
        integrations = integrations_where_specified_selector_is_consumer(resolved_specified_selectors) +
                        integrations_where_specified_selector_is_provider(resolved_specified_selectors)
        deduplicate_integrations(integrations)
      end

      # Find all the providers for the consumer versions specified in the query.
      # We must identify the providers for the consumer *versions*, not just the *consumers* (via the integrations table)
      # because the providers may change over time, as integrations get added and removed.
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] the resolved selectors that were specified in the query
      # @return [Array<PactBroker::Matrix::Integration>]
      def integrations_where_specified_selector_is_consumer(resolved_specified_selectors)
        resolved_specified_selectors.flat_map do | selector |
          # Could optimise this to all in one query, but it's a small gain
          IntegrationRow
            .integrations_for_selector_as_consumer(selector)
            .all
            .collect do | integration |
              Integration.from_hash(
                consumer_id: integration[:consumer_id],
                consumer_name: integration[:consumer_name],
                provider_id: integration[:provider_id],
                provider_name: integration[:provider_name],
                required: true # consumer requires the provider to be present
              )
            end
        end
      end

      # Returns a list of *potential* integrations for the pacticipants in the selectors, where the pacticipant is a provider.
      # Can't tell from the verifications table if a particular provider version has a consumer, as that is determined
      # by what is deployed to the environment, not what is verified. By looking in the integration table, we can identify
      # what consumers *may* be present in the target environment.
      # Find all the consumers for the providers specified in the query. Does not take into consideration the provider version (not sure why).
      # @param [Array<PactBroker::Matrix::ResolvedSelector>] the resolved selectors that were specified in the query
      # @return [Array<PactBroker::Matrix::Integration>]
      def integrations_where_specified_selector_is_provider(resolved_specified_selectors)
        integrations_involving_specified_providers = PactBroker::Integrations::Integration
                                                      .where(provider_id: resolved_specified_selectors.collect(&:pacticipant_id))
                                                      .eager(:consumer, :provider)
                                                      .all

        integrations_involving_specified_providers.collect do | integration |
          Integration.from_hash(
            consumer_id: integration.consumer.id,
            consumer_name: integration.consumer.name,
            provider_id: integration.provider.id,
            provider_name: integration.provider.name,
            required: false # provider does not require the consumer to be present
          )
        end
      end

      # Deduplicate a list of Integrations
      # @param [Array<PactBroker::Matrix::Integration>] integrations
      # @return [Array<PactBroker::Matrix::Integration>]
      def deduplicate_integrations(integrations)
        integrations
          .group_by{ | integration| [integration.consumer_id, integration.provider_id] }
          .values
          .collect { | duplicate_integrations | duplicate_integrations.find(&:required?) || duplicate_integrations.first }
      end

      # If a specified pacticipant is a consumer, then its provider is required to be deployed
      # to the same environment before the consumer can be deployed.
      # If a specified pacticipant is a provider only, then it may be deployed
      # without the consumer being present, but cannot break an existing consumer.
      def is_a_row_for_this_integration_required?(specified_pacticipant_names, consumer_name)
        specified_pacticipant_names.include?(consumer_name)
      end
    end
  end
end
