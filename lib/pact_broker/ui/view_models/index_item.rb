require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/ui/helpers/url_helper'
require 'pact_broker/date_helper'
require 'pact_broker/versions/abbreviate_number'
require 'pact_broker/configuration'

module PactBroker
  module UI
    module ViewDomain
      class IndexItem

        include PactBroker::Api::PactBrokerUrls

        def initialize relationship, options = {}
          @relationship = relationship
          @options = options
        end

        def consumer_name
          @relationship.consumer_name
        end

        def provider_name
          @relationship.provider_name
        end

        def consumer_version_number
          PactBroker::Versions::AbbreviateNumber.call(@relationship.consumer_version_number)
        end

        def consumer_version_order
          @relationship.consumer_version_order
        end

        def provider_version_number
          PactBroker::Versions::AbbreviateNumber.call(@relationship.provider_version_number)
        end

        def latest?
          @relationship.latest?
        end

        def consumer_version_latest_tag_names
          @relationship.tag_names
        end

        def provider_version_latest_tag_names
          @relationship.latest_verification_latest_tags.collect(&:name)
        end

        def consumer_group_url
          Helpers::URLHelper.group_url(consumer_name, base_url)
        end

        def provider_group_url
          Helpers::URLHelper.group_url(provider_name, base_url)
        end

        def latest_pact_url
          "#{pactigration_base_url(base_url, @relationship)}/latest"
        end

        def pact_url
          PactBroker::Api::PactBrokerUrls.pact_url(base_url, @relationship)
        end

        def pact_matrix_url
          Helpers::URLHelper.matrix_url(consumer_name, provider_name, base_url)
        end

        def any_webhooks?
          @relationship.any_webhooks?
        end

        def pact_versions_url
          PactBroker::Api::PactBrokerUrls.pact_versions_url(consumer_name, provider_name, base_url)
        end

        def integration_url
          PactBroker::Api::PactBrokerUrls.integration_url(consumer_name, provider_name, base_url)
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

        def show_settings?
          @relationship.latest?
        end

        def webhook_last_execution_date
          PactBroker::DateHelper.distance_of_time_in_words(@relationship.last_webhook_execution_date, DateTime.now) + " ago"
        end

        def webhook_url
          url = case @relationship.webhook_status
            when :none
              PactBroker::Api::PactBrokerUrls.webhooks_for_consumer_and_provider_url @relationship.latest_pact.consumer, @relationship.latest_pact.provider, base_url
            else
              PactBroker::Api::PactBrokerUrls.webhooks_status_url @relationship.latest_pact.consumer, @relationship.latest_pact.provider, base_url
          end
          PactBroker::Api::PactBrokerUrls.hal_browser_url(url, base_url)
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

        def publication_date_of_latest_pact_order
          @relationship.latest_pact.created_at.to_time.to_i
        end

        def pseudo_branch_verification_status
          case @relationship.pseudo_branch_verification_status
            when :success then "success"
            when :stale then "warning"
            when :failed then "danger"
            else ""
          end
        end

        def warning?
          pseudo_branch_verification_status == 'warning'
        end

        def verification_tooltip
          case @relationship.pseudo_branch_verification_status
          when :success
            "Successfully verified by #{provider_name} (#{short_version_number(@relationship.latest_verification_provider_version_number)})"
          when :stale
            "Pact has changed since last successful verification by #{provider_name} (#{short_version_number(@relationship.latest_verification_provider_version_number)})"
          when :failed
            "Verification by #{provider_name} (#{short_version_number(@relationship.latest_verification_provider_version_number)}) failed"
          else
            nil
          end
        end

        def <=> other
          comp = consumer_name.downcase <=> other.consumer_name.downcase
          return comp unless comp == 0
          comp = provider_name.downcase <=> other.provider_name.downcase
          return comp unless comp == 0
          other.consumer_version_order <=> consumer_version_order
        end

        def short_version_number version_number
          return "" if version_number.nil?
          if version_number.size > 12
            version_number[0..12] + "..."
          else
            version_number
          end
        end

        def base_url
          @options[:base_url]
        end
      end
    end
  end
end
