require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/ui/helpers/url_helper'
require 'pact_broker/date_helper'

module PactBroker
  module UI
    module ViewDomain
      class Relationship

        include PactBroker::Api::PactBrokerUrls

        def initialize relationship
          @relationship = relationship
        end

        def consumer_name
          @relationship.consumer_name
        end

        def provider_name
          @relationship.provider_name
        end

        def consumer_version_number
          short_version_number(@relationship.consumer_version_number)
        end

        def provider_version_number
          short_version_number(@relationship.provider_version_number)
        end

        def tag_names
          @relationship.tag_names.any? ? " (#{@relationship.tag_names.join(', ')}) ": ""
        end

        def consumer_group_url
          Helpers::URLHelper.group_url consumer_name
        end

        def provider_group_url
          Helpers::URLHelper.group_url provider_name
        end

        def pact_url
          "#{pactigration_base_url('', @relationship)}/latest"
        end

        def any_webhooks?
          @relationship.any_webhooks?
        end

        def webhook_label
          return "" unless show_webhook_status?
          case @relationship.webhook_status
            when :none then "Create"
            when :success, :failure then webhook_last_execution_date
            when :retrying then "Retrying"
            when :not_run then "Not run"
          end
        end

        def webhook_status
          return "" unless show_webhook_status?
          case @relationship.webhook_status
            when :success then "success"
            when :failure then "danger"
            when :retrying then "warning"
            else ""
          end
        end

        def show_webhook_status?
          @relationship.latest?
        end

        def webhook_last_execution_date
          PactBroker::DateHelper.distance_of_time_in_words(@relationship.last_webhook_execution_date, DateTime.now) + " ago"
        end

        def webhook_url
          url = case @relationship.webhook_status
            when :none
              PactBroker::Api::PactBrokerUrls.webhooks_for_pact_url @relationship.latest_pact.consumer, @relationship.latest_pact.provider
            else
              PactBroker::Api::PactBrokerUrls.webhooks_status_url @relationship.latest_pact.consumer, @relationship.latest_pact.provider
          end
          "/hal-browser/browser.html##{url}"
        end

        def last_verified_date
          if @relationship.ever_verified?
            date = @relationship.latest_verification.execution_date
            PactBroker::DateHelper.distance_of_time_in_words(date, DateTime.now) + " ago"
          else
            ""
          end
        end

        def publication_date_of_latest_pact
          date = @relationship.latest_pact.created_at
          PactBroker::DateHelper.distance_of_time_in_words(date, DateTime.now) + " ago"
        end

        def verification_status
          case @relationship.verification_status
            when :success then "success"
            when :stale then "warning"
            when :failed then "danger"
            else ""
          end
        end

        def warning?
          verification_status == 'warning'
        end

        def verification_tooltip
          case @relationship.verification_status
          when :success
            "Successfully verified by #{provider_name} (v#{short_version_number(@relationship.latest_verification_provider_version_number)})"
          when :stale
            "Pact has changed since last successful verification by #{provider_name} (v#{short_version_number(@relationship.latest_verification_provider_version_number)})"
          when :failed
            "Verification by #{provider_name} (v#{short_version_number(@relationship.latest_verification_provider_version_number)}) failed"
          else
            nil
          end
        end

        def <=> other
          comp = consumer_name.downcase <=> other.consumer_name.downcase
          return comp unless comp == 0
          provider_name.downcase <=> other.provider_name.downcase
        end

        def short_version_number version_number
          return "" if version_number.nil?
          if version_number.size > 12
            version_number[0..12] + "..."
          else
            version_number
          end
        end
      end
    end
  end
end