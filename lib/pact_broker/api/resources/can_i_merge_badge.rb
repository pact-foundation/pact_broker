require "pact_broker/api/resources/base_resource"
require "pact_broker/api/resources/badge_methods"

module PactBroker
  module Api
    module Resources
      class CanIMergeBadge < BaseResource
        include BadgeMethods # This module contains all necessary webmachine methods for badge implementation

        def badge_url 
          if pacticipant.nil? # pacticipant method is defined in BaseResource
            # if the pacticipant is nil, we return an error badge url
            badge_service.error_badge_url("pacticipant", "not found")
          elsif version.nil?
            # when there is no main branch version, we return an error badge url
            badge_service.error_badge_url("main branch version", "not found")
          else
            # when badge is available, set cache based on configuration
            set_cache_control(default_cache_for_succesful_badge)
            # we call badge_service to build the badge url
            badge_service.can_i_merge_badge_url(deployable: results)
          end
        end
        
        private

        def default_cache_for_succesful_badge
          PactBroker.configuration.badge_default_cache_setting
        end

        def results
          # can_i_merge returns true or false if the main branch version is compatible with all the integrations
          @results ||= matrix_service.can_i_merge(pacticipant: pacticipant, latest_main_branch_version: version)
        end

        def version
          @version ||= version_service.find_latest_version_from_main_branch(pacticipant) 
        end
      end
    end
  end
end
