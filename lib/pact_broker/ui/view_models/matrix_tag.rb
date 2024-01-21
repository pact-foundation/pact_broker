require "pact_broker/api/pact_broker_urls"
require "pact_broker/ui/helpers/url_helper"
require "pact_broker/date_helper"

module PactBroker
  module UI
    module ViewModels
      class MatrixTag
        include PactBroker::Api::PactBrokerUrls

        attr_reader :name, :pacticipant_name, :version_number

        def initialize params
          @name = params[:name]
          @pacticipant_name = params[:pacticipant_name]
          @version_number = params[:version_number]
          @created_at = params[:created_at]
          @latest = !!params[:latest]
        end

        def tooltip
          if @latest
            "This is the latest version of #{pacticipant_name} with tag \"#{@name}\". Tag created #{relative_date(@created_at)}."
          else
            "Tag created #{relative_date(@created_at)}. A more recent version of #{pacticipant_name} with tag \"#{name}\" exists."
          end
        end

        def url
          hal_browser_url("/pacticipants/#{ERB::Util.url_encode(pacticipant_name)}/versions/#{ERB::Util.url_encode(version_number)}/tags/#{ERB::Util.url_encode(name)}")
        end

        def relative_date date
          DateHelper.distance_of_time_in_words(date, DateTime.now) + " ago"
        end
      end
    end
  end
end
