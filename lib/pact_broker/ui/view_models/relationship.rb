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

        def consumer_group_url
          Helpers::URLHelper.group_url consumer_name
        end

        def provider_group_url
          Helpers::URLHelper.group_url provider_name
        end

        def latest_pact_url
          "#{pactigration_base_url('', @relationship)}/latest"
        end

        def any_webhooks?
          @relationship.any_webhooks?
        end

        def webhook_status
          if any_webhooks?
            ["success", "danger",""][rand(3)]
          else
            ""
          end
        end

        def webhook_last_execution_date

          if any_webhooks?
            publication_date_of_latest_pact
          else
            "None created"
          end

        end

        def webhooks_url
          url = PactBroker::Api::PactBrokerUrls.webhooks_for_pact_url @relationship.latest_pact.consumer, @relationship.latest_pact.provider, ''
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
            "Successfully verified by #{provider_name} (v#{@relationship.latest_verification_provider_version})"
          when :stale
            "Pact has changed since last successful verification by #{provider_name} (v#{@relationship.latest_verification_provider_version})"
          when :failed
            "Verification by #{provider_name} (v#{@relationship.latest_verification_provider_version}) failed"
          else
            nil
          end
        end

        def <=> other
          comp = consumer_name.downcase <=> other.consumer_name.downcase
          return comp unless comp == 0
          provider_name.downcase <=> other.provider_name.downcase
        end

      end
    end
  end
end