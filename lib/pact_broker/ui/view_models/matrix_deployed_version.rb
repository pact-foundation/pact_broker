require "pact_broker/api/pact_broker_urls"
require "pact_broker/ui/helpers/url_helper"
require "pact_broker/date_helper"

module PactBroker
  module UI
    module ViewModels
      class MatrixDeployedVersion
        include PactBroker::Api::PactBrokerUrls

        def initialize deployed_version
          @deployed_version = deployed_version
        end

        def environment_name
          deployed_version.environment.name
        end

        def tooltip
          "Currently deployed to #{deployed_version.environment.display_name} (#{relative_date(deployed_version.created_at)})"
        end

        def url
          hal_browser_url(deployed_version_url(deployed_version))
        end

        private

        attr_reader :deployed_version

        def relative_date date
          DateHelper.distance_of_time_in_words(date, DateTime.now) + " ago"
        end
      end
    end
  end
end
