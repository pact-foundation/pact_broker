require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/ui/helpers/url_helper'
require 'pact_broker/date_helper'
require 'pact_broker/ui/view_models/matrix_tag'
require 'pact_broker/versions/abbreviate_number'

module PactBroker
  module UI
    module ViewDomain
      class MatrixLine

        include PactBroker::Api::PactBrokerUrls

        def initialize line
          @line = line
          @overwritten = false # true if the pact was revised and this revision is no longer the latest
        end

        def provider_name
          @line[:provider_name]
        end

        def provider_name_url
          hal_browser_url(pacticipant_url_from_params(pacticipant_name: provider_name))
        end

        def consumer_name
          @line[:consumer_name]
        end

        def consumer_name_url
          hal_browser_url(pacticipant_url_from_params(pacticipant_name: consumer_name))
        end

        def pact_version_sha
          @line[:pact_version_sha]
        end

        # verification number, used in verification_url method
        def number
          @line[:verification_number]
        end

        def pact_revision_number
          @line[:pact_revision_number]
        end

        def consumer_name
          @line[:consumer_name]
        end

        def consumer_version_number
          @line[:consumer_version_number]
        end

        def display_consumer_version_number
          PactBroker::Versions::AbbreviateNumber.call(consumer_version_number)
        end

        def consumer_version_number_url
          params = { pacticipant_name: consumer_name, version_number: consumer_version_number }
          hal_browser_url(version_url_from_params(params))
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

        def display_provider_version_number
          PactBroker::Versions::AbbreviateNumber.call(provider_version_number)
        end

        def provider_version_order
          @line[:provider_version_order]
        end

        def provider_version_number_url
          params = { pacticipant_name: provider_name, version_number: provider_version_number }
          hal_browser_url(version_url_from_params(params))
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
            .collect{ | tag | MatrixTag.new(tag.to_hash.merge(pacticipant_name: consumer_name, version_number: consumer_version_number)) }
        end

        def other_consumer_version_tags
          @line[:consumer_version_tags]
            .select{ | tag | !tag[:latest] }
            .collect{ | tag | MatrixTag.new(tag.to_hash.merge(pacticipant_name: consumer_name, version_number: consumer_version_number)) }
        end

        def latest_provider_version_tags
          @line[:provider_version_tags]
            .select{ | tag | tag[:latest] }
            .collect{ | tag | MatrixTag.new(tag.to_hash.merge(pacticipant_name: provider_name, version_number: provider_version_number)) }
        end

        def other_provider_version_tags
          @line[:provider_version_tags]
            .select{ | tag | !tag[:latest] }
            .collect{ | tag | MatrixTag.new(tag.to_hash.merge(pacticipant_name: provider_name, version_number: provider_version_number)) }
        end

        def orderable_fields
          [consumer_name, consumer_version_order, pact_revision_number, provider_name, @line[:verification_id]]
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

        def verification_status_url
          hal_browser_url(verification_url(self))
        end

        def pact_publication_date
          relative_date(@line[:pact_created_at])
        end

        def pact_publication_date_url
          pact_url_from_params('', @line)
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

        def overwritten?
          @overwritten
        end

        def overwritten= overwritten
          @overwritten = overwritten
        end
      end
    end
  end
end