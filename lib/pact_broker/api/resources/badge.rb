require 'pact_broker/api/resources/base_resource'
require 'pact_broker/verifications/verification_status'
require 'pact_broker/configuration'

module PactBroker
  module Api
    module Resources

      class Badge < BaseResource

        def allowed_methods
          ['GET']
        end

        def content_types_provided
          [['image/svg+xml', :to_svg]]
        end

        def resource_exists?
          true
        end

        def is_authorized?(authorization_header)
          super || PactBroker.configuration.enable_public_badge_access
        end

        def forbidden?
          false
        end

        private

        def to_svg
          response.headers['Cache-Control'] = 'no-cache'
          comment + badge_service.pact_verification_badge(pact, label, initials, verification_status)
        end

        def pact
          @pact ||= pact_service.find_latest_pact(identifier_from_path)
        end

        def latest_verification
          return nil unless pact
          @verification ||= verification_service.find_latest_verification_for(pact.consumer, pact.provider, identifier_from_path[:tag])
        end

        def verification_status
          @verification_status ||= PactBroker::Verifications::Status.new(pact, latest_verification).to_sym
        end

        def label
          request.query['label']
        end

        def initials
          request.query['initials'] == 'true'
        end

        def comment
          consumer_version_number = pact ? pact.consumer_version_number : "?"
          provider_version_number = latest_verification ? latest_verification.provider_version_number : "?"
          "<!-- #{identifier_from_path[:consumer_name]} version #{consumer_version_number} #{identifier_from_path[:provider_name]} version #{provider_version_number} -->\n"
        end
      end
    end
  end
end
