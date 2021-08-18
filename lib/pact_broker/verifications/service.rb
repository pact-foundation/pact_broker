require "delegate"
require "pact_broker/repositories"
require "pact_broker/api/decorators/verification_decorator"
require "pact_broker/verifications/summary_for_consumer_version"
require "pact_broker/logging"
require "pact_broker/hash_refinements"
require "pact_broker/events/publisher"
require "pact_broker/verifications/required_verification"

module PactBroker
  module Verifications
    module Service

      extend Forwardable

      extend self

      extend PactBroker::Repositories
      extend PactBroker::Services
      include PactBroker::Logging
      using PactBroker::HashRefinements
      extend PactBroker::Events::Publisher

      delegate [:any_verifications?] => :verification_repository

      def next_number
        verification_repository.next_number
      end

      # verified_pacts is an array of SelectedPact objects
      def create next_verification_number, params, verified_pacts, event_context
        first_verified_pact = verified_pacts.first
        logger.info "Creating verification #{next_verification_number} for pact_version_sha=#{first_verified_pact.pact_version_sha}", payload: params.reject{ |k,_| k == "testResults"}
        verification = PactBroker::Domain::Verification.new
        provider_version_number = params.fetch("providerApplicationVersion")
        PactBroker::Api::Decorators::VerificationDecorator.new(verification).from_hash(params)
        verification.wip = params.fetch("wip")
        verification.number = next_verification_number
        verification.consumer_version_selector_hashes = event_context[:consumer_version_selectors]
        pact_version = pact_repository.find_pact_version(first_verified_pact.consumer, first_verified_pact.provider, first_verified_pact.pact_version_sha)
        verification = verification_repository.create(verification, provider_version_number, pact_version)
        pact_service.set_latest_verification(verified_pacts, verification)
        # TODO set the latest_verification_id on each PactPublication
        # TODO broadcast the verified_pacts for the webhooks
        broadcast_events(verification, first_verified_pact.pact, event_context)

        verification
      end

      def delete(verification)
        webhook_service.delete_all_webhook_related_objects_by_verification_ids(verification.id)
        verification_repository.delete(verification.id)
      end

      def errors params
        contract = PactBroker::Api::Contracts::VerificationContract.new(PactBroker::Domain::Verification.new)
        contract.validate(params)
        contract.errors
      end

      def find params
        verification_repository.find(params.fetch(:consumer_name), params.fetch(:provider_name), params.fetch(:pact_version_sha), params.fetch(:verification_number))
      end

      def find_latest_for_pact(pact)
        verification_repository.find_latest_for_pact(pact)
      end

      def find_by_id id
        PactBroker::Domain::Verification.find(id: id)
      end

      def find_latest_verifications_for_consumer_version params
        verification_repository.find_latest_verifications_for_consumer_version params[:consumer_name], params[:consumer_version_number]
      end

      def find_latest_verification_for consumer, provider, tag = nil
        verification_repository.find_latest_verification_for consumer.name, provider.name, tag
      end

      def find_latest_verification_for_tags consumer_name, provider_name, consumer_version_tag_name, provider_version_tag_name
        verification_repository.find_latest_verification_for_tags(consumer_name, provider_name, consumer_version_tag_name, provider_version_tag_name)
      end

      def search_for_latest consumer_name, provider_name
        verification_repository.search_for_latest(consumer_name, provider_name)
      end

      def verification_summary_for_consumer_version params
        verifications = find_latest_verifications_for_consumer_version(params)
        pacts = pact_service.find_by_consumer_version(params)
        SummaryForConsumerVersion.new(verifications, pacts)
      end

      def delete_all_verifications_between(consumer_name, options)
        verification_repository.delete_all_verifications_between(consumer_name, options)
      end

      def calculate_required_verifications_for_pact(pact)
        pact_version = PactBroker::Pacts::PactVersion.for_pact_domain(pact)
        required_verifications =  required_verifications_for_main_branch(pact_version) +
                                  required_verifications_for_deployed_versions(pact_version) +
                                  required_verifications_for_released_versions(pact_version)
        required_verifications
          .group_by(&:provider_version)
          .values
          .flat_map { | required_verifications_for_provider_version | required_verifications_for_provider_version.reduce(&:+) }
      end

      def broadcast_events(verification, pact, event_context)
        event_params = {
          pact: pact,
          verification: verification,
          event_context: event_context.merge(provider_version_tags: verification.provider_version_tag_names)
        }

        broadcast(:provider_verification_published, event_params)
        if verification.success
          broadcast(:provider_verification_succeeded, event_params)
        else
          broadcast(:provider_verification_failed, event_params)
        end
      end
      private :broadcast_events

      def identify_required_verification(pact_version, provider_version, description)
        any_verifications = PactBroker::Domain::Verification.where(pact_version_id: pact_version.id, provider_version_id: provider_version.id).any?
        if !any_verifications
          RequiredVerification.new(provider_version: provider_version, provider_version_descriptions: [description])
        end
      end
      private :identify_required_verification

      def required_verifications_for_main_branch(pact_version)
        latest_version_from_main_branch = [version_service.find_latest_version_from_main_branch(pact_version.provider)].compact

        latest_version_from_main_branch.collect do | main_branch_version |
          identify_required_verification(pact_version, main_branch_version, "latest version from main branch")
        end.compact
      end
      private :required_verifications_for_main_branch

      def required_verifications_for_deployed_versions(pact_version)
        deployed_versions = deployed_version_service.with_no_scope do | unscoped_service |
          unscoped_service.find_currently_deployed_versions_for_pacticipant(pact_version.provider)
        end
        deployed_versions.collect do | deployed_version |
          identify_required_verification(pact_version, deployed_version.version, "currently deployed version (#{deployed_version.environment_name})")
        end.compact
      end
      private :required_verifications_for_deployed_versions

      def required_verifications_for_released_versions(pact_version)
        released_versions = released_version_service.with_no_scope do | unscoped_service |
          unscoped_service.find_currently_supported_versions_for_pacticipant(pact_version.provider)
        end
        released_versions.collect do | released_version |
          identify_required_verification(pact_version, released_version.version, "currently released version (#{released_version.environment_name})")
        end.compact
      end
      private :required_verifications_for_released_versions
    end
  end
end
