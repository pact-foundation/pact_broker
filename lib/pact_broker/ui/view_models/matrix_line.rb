require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/ui/helpers/url_helper'
require 'pact_broker/date_helper'

module PactBroker
  module UI
    module ViewDomain
      class MatrixLine

        include PactBroker::Api::PactBrokerUrls

        def initialize line
          @line = line
        end

        def provider_name
          @line[:provider_name]
        end

        def consumer_name
          @line[:consumer_name]
        end

        def pact_version_sha
          @line[:pact_version_sha]
        end

        # verification number
        def number
          @line[:number]
        end

        def consumer_name
          @line[:consumer_name]
        end

        def consumer_version_number
          @line[:consumer_version_number]
        end

        def consumer_version_number_url
          pact_url_from_params('', @line)
        end

        def consumer_version_order
          @line[:consumer_version_order]
        end

        def provider_name
          @line[:provider_name]
        end

        def provider_version_number
          @line[:provider_version_number]
        end

        def provider_version_order
          @line[:provider_version_order]
        end

        def provider_version_number_url
          hal_browser_url(verification_url(self))
        end

        def provider_version_order
          if @line[:execution_date]
            @line[:execution_date].to_time.to_i
          else
            0
          end
        end

        def orderable_fields
          [consumer_name, provider_name, consumer_version_order, provider_version_order]
        end

        def <=> other
          self.orderable_fields <=> other.orderable_fields
        end

        def verification_status
          if @line[:verification_executed_at]
            DateHelper.distance_of_time_in_words(@line[:verification_executed_at], DateTime.now) + " ago"
          else
            ''
          end
          # case @line[:success]
          #   when true then "Verified"
          #   when false then "Failed"
          #   else ''
          # end
        end

        def pact_publication_date
          DateHelper.distance_of_time_in_words(@line[:pact_created_at], DateTime.now) + " ago"
        end

        def pact_published_order
          @line[:pact_created_at].to_time.to_i
        end

        def verification_status_class
          case @line[:success]
            when true then 'success'
            when false then 'danger'
            else ''
          end
        end
      end
    end
  end
end