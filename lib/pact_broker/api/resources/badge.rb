require 'pact_broker/api/resources/base_resource'
require 'pact_broker/verifications/pseudo_branch_status'
require 'pact_broker/configuration'

module PactBroker
  module Api
    module Resources
      class Badge < BaseResource

        def allowed_methods
          ["GET", "OPTIONS"]
        end

        def content_types_provided
          [['image/svg+xml', :to_svg]]
        end

        def resource_exists?
          !badge_service.can_provide_badge_using_redirect?
        end

        # Only called if resource_exists? returns false
        def previously_existed?
          true
        end

        def is_authorized?(authorization_header)
          super || PactBroker.configuration.enable_public_badge_access
        end

        def forbidden?
          false
        end

        def to_svg
          response.headers['Cache-Control'] = 'no-cache'
          comment + badge_service.pact_verification_badge(pact, label, initials, pseudo_branch_verification_status)
        end

        def moved_temporarily?
          response.headers['Cache-Control'] = 'no-cache'
          badge_service.pact_verification_badge_url(pact, label, initials, pseudo_branch_verification_status)
        end

        private

        def pact
          @pact ||= pact_service.find_latest_pact(identifier_from_path)
        end

        def latest_verification
          return nil unless pact
          @verification ||= verification_service.find_latest_verification_for(pact.consumer, pact.provider, identifier_from_path[:tag])
        end

        def pseudo_branch_verification_status
          @pseudo_branch_verification_status ||= PactBroker::Verifications::PseudoBranchStatus.new(pact, latest_verification).to_sym
        end

        def label
          request.query['label']
        end

        def initials
          request.query['initials'] == 'true'
        end

        def comment
          consumer_version_number = pact ? pact.consumer_version_number : "?"
          pact_revision = pact ? pact.revision_number : "?"
          provider_version_number = latest_verification ? latest_verification.provider_version_number : "?"
          verification_number =  latest_verification ? latest_verification.number : "?"
          "<!-- #{identifier_from_path[:consumer_name]} version #{consumer_version_number} revision #{pact_revision} #{identifier_from_path[:provider_name]} version #{provider_version_number} number #{verification_number} -->\n"
        end
      end
    end
  end
end
