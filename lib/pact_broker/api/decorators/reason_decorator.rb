module PactBroker
  module Api
    module Decorators
      class ReasonDecorator
        def initialize(reason)
          @reason = reason
        end

        def to_s
          case reason
          when PactBroker::Matrix::PactNotEverVerifiedByProvider
            "There is no verified pact between #{reason.consumer_selector.description} and #{reason.provider_selector.description}"
          when PactBroker::Matrix::PactNotVerifiedByRequiredProviderVersion
            "There is no verified pact between #{reason.consumer_selector.description} and #{reason.provider_selector.description}"
          when PactBroker::Matrix::VerificationFailed
            "The verification between #{reason.consumer_selector.description} and #{reason.provider_selector.description} failed"
          when PactBroker::Matrix::SpecifiedVersionDoesNotExist
            version_does_not_exist_description(reason.selector)
          when PactBroker::Matrix::VerificationFailed
            "The verification for the pact between #{reason.consumer_selector.description} and #{reason.provider_selector.description} failed"
          when PactBroker::Matrix::NoDependenciesMissing
            "There are no missing dependencies"
          when PactBroker::Matrix::Successful
            "All required verification results are published and successful"
          else
            reason
          end
        end

        private

        attr_reader :reason

        def version_does_not_exist_description selector
          if selector.version_does_not_exist?
            if selector.tag
              "No version with tag #{selector.tag} exists for #{selector.pacticipant_name}"
            elsif selector.pacticipant_version_number
              "No pacts or verifications have been published for version #{selector.pacticipant_version_number} of #{selector.pacticipant_name}"
            else
              "No pacts or verifications have been published for #{selector.pacticipant_name}"
            end
          else
            ""
          end
        end
      end
    end
  end
end
