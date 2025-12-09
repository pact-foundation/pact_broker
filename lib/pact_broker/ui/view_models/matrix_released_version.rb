require "pact_broker/api/pact_broker_urls"
require "pact_broker/ui/helpers/url_helper"
require "pact_broker/date_helper"

module PactBroker
  module UI
    module ViewModels
      class MatrixReleasedVersion
        include PactBroker::Api::PactBrokerUrls

        def initialize released_version
          @released_version = released_version
        end

        def environment_name
          released_version.environment.name
        end

        def tooltip
          "Currently released and supported in #{released_version.environment.display_name} (#{relative_date(released_version.created_at)})"
        end

        def url
          hal_browser_url(released_version_url(released_version))
        end

        private

        attr_reader :released_version

        def relative_date date
          DateHelper.distance_of_time_in_words(date, DateTime.now) + " ago"
        end
      end
    end
  end
end
