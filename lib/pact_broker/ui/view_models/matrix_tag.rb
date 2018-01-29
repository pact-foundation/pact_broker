require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/ui/helpers/url_helper'
require 'pact_broker/date_helper'

module PactBroker
  module UI
    module ViewDomain
      class MatrixTag

        include PactBroker::Api::PactBrokerUrls

        def initialize params
          @params = params
          @name = params[:name]
          @version_number = params[:version_number]
          @created_at = params[:created_at]
          @latest = !!params[:latest]
        end

        def name
          @params[:name]
        end

        def tooltip
          if @latest
            "Version #{@version_number} is the latest version with tag #{@name}. Tag created #{relative_date(@created_at)}."
          else
            "Tag created #{relative_date(@created_at)}."
          end
        end

        def url
          hal_browser_url("/pacticipants/#{ERB::Util.url_encode(@params[:pacticipant_name])}/versions/#{@params[:version_number]}/tags/#{@params[:name]}")
        end

        def relative_date date
          DateHelper.distance_of_time_in_words(date, DateTime.now) + " ago"
        end
      end
    end
  end
end
