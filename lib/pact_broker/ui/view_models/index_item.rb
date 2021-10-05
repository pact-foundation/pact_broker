require "pact_broker/api/pact_broker_urls"
require "pact_broker/ui/helpers/url_helper"
require "pact_broker/date_helper"
require "pact_broker/versions/abbreviate_number"
require "pact_broker/configuration"
require "pact_broker/ui/view_models/index_item_branch_head"
require "pact_broker/ui/view_models/index_item_provider_branch_head"
require "forwardable"

module PactBroker
  module UI
    module ViewDomain
      class IndexItem
        extend Forwardable

        delegate [
          :consumer_version_branch,
          :consumer_version_branches,
          :provider_version_branch,
          :provider_version_branches,
          :latest_for_branch?,
          :consumer_version_environment_names,
          :provider_version_environment_names,
          :latest_verification
        ] => :relationship


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
          @relationship.consumer_version_number
        end

        def display_consumer_version_number
          PactBroker::Versions::AbbreviateNumber.call(consumer_version_number)
        end

        def consumer_version_order
          @relationship.consumer_version_order
        end

        def provider_version_number
          @relationship.provider_version_number
        end

        def display_provider_version_number
          PactBroker::Versions::AbbreviateNumber.call(provider_version_number)
        end

        def display_latest_label?
          consumer_version_latest_tag_names.empty? && @relationship.tag_names.empty?
        end

        def latest?
          @relationship.latest?
        end

        def consumer_version_branch_heads
          @relationship.consumer_version_branch_heads.collect do | branch_head |
            IndexItemBranchHead.new(branch_head, consumer_name)
          end
        end

        def consumer_version_latest_tag_names
          @relationship.tag_names
        end

        def provider_version_latest_tag_names
          @relationship.latest_verification_latest_tags.collect(&:name)
        end

        def provider_version_branch_heads
          @relationship.provider_version_branch_heads.collect do | branch_head |
            IndexItemProviderBranchHead.new(branch_head, provider_name)
          end
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

        def dashboard_url
          Helpers::URLHelper.dashboard_url(consumer_name, provider_name, base_url)
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
            date = latest_verification.execution_date
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
            when :failed_pending then "danger"
            else ""
          end
        end

        def failed_and_pact_pending?
          latest_verification&.failed_and_pact_pending?
        end

        def warning?
          pseudo_branch_verification_status == "warning"
        end

        def verification_tooltip
          case @relationship.pseudo_branch_verification_status
          when :success
            "Successfully verified by #{provider_name} (#{short_version_number(@relationship.latest_verification_provider_version_number)})"
          when :stale
            # TODO when there are multiple tags/branches, the tag/branch shown may not be the relevant one, but
            # it shouldn't happen very often. Can change this to "tag a or b"
            desc =  if @relationship.consumer_version_branches.any?
                      "from branch #{@relationship.consumer_version_branches.first} "
                    elsif @relationship.tag_names.any?
                      "with tag #{@relationship.tag_names.first} "
                    else
                      ""
                    end
            "Pact #{desc}has changed since last successful verification by #{provider_name} (#{short_version_number(@relationship.latest_verification_provider_version_number)})"
          when :failed_pending
            "Verification by #{provider_name} (#{short_version_number(@relationship.latest_verification_provider_version_number)}) failed, but did not fail the build as the pact content was in pending state for that provider branch"
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

        def show_menu?
          !view_by_environment? && (@relationship.tag_names.any? || consumer_version_branches.any?)
        end

        def base_url
          @options[:base_url]
        end

        def pact_tags
          @relationship.tag_names.map do |tag|
            {
              name: tag,
              deletionUrl: PactBroker::Api::PactBrokerUrls.tagged_pact_versions_url(consumer_name, provider_name, tag, base_url)
            }
          end.to_json
        end

        def pact_branches
          consumer_version_branches.map do | branch_name |
            {
              name: branch_name,
              deletionUrl: PactBroker::Api::PactBrokerUrls.pact_versions_for_branch_url(consumer_name, provider_name, branch_name, base_url)
            }
          end.to_json
        end

        def view_by_environment?
          @options[:view] == "environment"
        end

        private

        attr_reader :relationship
      end
    end
  end
end
