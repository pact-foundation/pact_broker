require 'pact_broker/api/resources/base_resource'
require 'pact_broker/verifications/verification_status'

module PactBroker
  module Api
    module Resources

      class LatestVerificationForPact < BaseResource

        def allowed_methods
          ["GET"]
        end

        def content_types_provided
          [["image/svg+xml", :to_svg]]
        end

        def resource_exists?
          true
        end

        private

        def to_svg
          File.read(svg_file)
        end

        def pact
          @pact ||= pact_service.find_latest_pact(identifier_from_path)
        end

        def latest_verification
          return nil unless pact
          @verification ||= verification_service.find_latest_verification_for(pact.consumer, pact.provider)
        end

        def verification_status
          @verification_status ||= PactBroker::Verifications::Status.new(pact, latest_verification).to_sym
        end

        def svg_file
          svg = case verification_status.to_sym
            when :never then "pacts-unknown-lightgrey.svg"
            when :success then "pacts-verified-brightgreen.svg"
            when :stale then "pacts-unknown-orange.svg"
            when :failed then "pacts-failed-red.svg"
          end
          PactBroker.project_root.join("public", "images", svg)
        end
      end
    end
  end
end
