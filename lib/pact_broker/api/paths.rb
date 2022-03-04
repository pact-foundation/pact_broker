module PactBroker
  module Api
    module Paths
      PACT_BADGE_PATH =         %r{^/pacts/provider/[^/]+/consumer/.*/badge(?:\.[A-Za-z]+)?$}.freeze
      MATRIX_BADGE_PATH =       %r{^/matrix/provider/[^/]+/latest/[^/]+/consumer/[^/]+/latest/[^/]+/badge(?:\.[A-Za-z]+)?$}.freeze
      CAN_I_DEPLOY_TAG_BADGE_PATH = %r{^/pacticipants/[^/]+/latest-version/[^/]+/can-i-deploy/to/[^/]+/badge(?:\.[A-Za-z]+)?$}.freeze
      CAN_I_DEPLOY_BRANCH_ENV_BADGE_PATH = %r{^/pacticipants/[^/]+/branches/[^/]+/latest-version/can-i-deploy/to-environment/[^/]+/badge(?:\.[A-Za-z]+)?$}.freeze
      VERIFICATION_RESULTS =    %r{^/pacts/provider/[^/]+/consumer/[^/]+/pact-version/[^/]+/verification-results/[^/]+}

      BADGE_PATHS = [PACT_BADGE_PATH, MATRIX_BADGE_PATH, CAN_I_DEPLOY_TAG_BADGE_PATH, CAN_I_DEPLOY_BRANCH_ENV_BADGE_PATH]

      extend self

      def is_verification_results_path?(path)
        path.start_with?("/pacts") && (path =~ VERIFICATION_RESULTS)
      end

      def is_badge_path?(path)
        # Optimise by checking include? first - regexp slow
        path.include?("/badge") && BADGE_PATHS.any?{ | regex | path =~ regex }
      end
    end
  end
end
