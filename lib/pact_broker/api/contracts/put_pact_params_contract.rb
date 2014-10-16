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

        validate :consumer_name_in_path_matches_consumer_name_in_pact
        validate :provider_name_in_path_matches_provider_name_in_pact

        def consumer_name_in_path_matches_consumer_name_in_pact
          name_in_path_matches_name_in_pact consumer
        end

        def provider_name_in_path_matches_provider_name_in_pact
          name_in_path_matches_name_in_pact provider
        end

        def name_in_path_matches_name_in_pact pacticipant
          if present?(pacticipant.name) && present?(pacticipant.name_in_pact)
            if pacticipant.name != pacticipant.name_in_pact
              errors.add(:base, validation_message('pacticipant_name_mismatch', pacticipant.to_h).capitalize)
            end
          end
        end

        def blank? string
          string && string.strip.empty?
        end

        def present? string
          string && !blank?(string)
        end

      end
    end
  end
end
