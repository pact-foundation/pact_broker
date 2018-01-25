require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/ui/helpers/url_helper'
require 'pact_broker/date_helper'
require 'pact_broker/ui/view_models/matrix_tag'

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
          if @line[:verification_executed_at]
            @line[:verification_executed_at].to_time.to_i
          else
            0
          end
        end

        def latest_consumer_version_tags
          @line[:consumer_version_tags]
            .select{ | tag | tag[:latest] }
            .collect{ | tag | MatrixTag.new(tag.merge(pacticipant_name: consumer_name, version_number: consumer_version_number)) }
        end

        def other_consumer_version_tags
          @line[:consumer_version_tags]
            .select{ | tag | !tag[:latest] }
            .collect{ | tag | MatrixTag.new(tag.merge(pacticipant_name: consumer_name, version_number: consumer_version_number)) }
        end

        def latest_provider_version_tags
          @line[:provider_version_tags]
            .select{ | tag | tag[:latest] }
            .collect{ | tag | MatrixTag.new(tag.merge(pacticipant_name: provider_name, version_number: provider_version_number)) }
        end

        def other_provider_version_tags
          @line[:provider_version_tags]
            .select{ | tag | !tag[:latest] }
            .collect{ | tag | MatrixTag.new(tag.merge(pacticipant_name: provider_name, version_number: provider_version_number)) }
        end

        def orderable_fields
          [consumer_name, consumer_version_order, @line[:pact_revision_number], provider_name, @line[:verification_id]]
        end

        def <=> other
          (self.orderable_fields <=> other.orderable_fields) * -1
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
          relative_date(@line[:pact_created_at])
        end

        def relative_date date
          DateHelper.distance_of_time_in_words(date, DateTime.now) + " ago"
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