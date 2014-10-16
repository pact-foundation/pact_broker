require 'reform'
require 'reform/contract'
require 'versionomy'
require 'pact_broker/messages'
require 'pact_broker/constants'
require 'pact_broker/api/contracts/post_pact_params_contract'

module PactBroker
  module Api
    module Contracts

      class PutPactParamsContract < PostPactParamsContract

        property :consumer_name_in_pact
        property :provider_name_in_pact

        validate :consumer_name_in_path_matches_consumer_name_in_pact
        validate :provider_name_in_path_matches_provider_name_in_pact

        def consumer_name_in_path_matches_consumer_name_in_pact
          if !empty?(consumer_name) && !empty?(consumer_name_in_pact)
            if consumer_name != consumer_name_in_pact
              errors.add(:base, validation_message('pacticipant_name_mismatch', pacticipant: 'consumer', name_in_pact: consumer_name_in_pact, name: consumer_name).capitalize)
            end
          end
        end

        def provider_name_in_path_matches_provider_name_in_pact
          if !empty?(provider_name) && !empty?(provider_name_in_pact)
            if provider_name != provider_name_in_pact
              errors.add(:base, validation_message('pacticipant_name_mismatch', pacticipant: 'provider', name_in_pact: provider_name_in_pact, name: provider_name).capitalize)
            end
          end
        end

      end
    end
  end
end
