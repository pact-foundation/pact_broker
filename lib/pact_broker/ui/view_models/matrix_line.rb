require "pact_broker/api/pact_broker_urls"
require "pact_broker/ui/helpers/url_helper"
require "pact_broker/date_helper"
require "pact_broker/ui/view_models/matrix_tag"
require "pact_broker/ui/view_models/matrix_deployed_version"
require "pact_broker/versions/abbreviate_number"
require "pact_broker/messages"
require "forwardable"

module PactBroker
  module UI
    module ViewDomain
      class MatrixLine
        include PactBroker::Api::PactBrokerUrls
        include PactBroker::Messages
        extend Forwardable

        delegate [:consumer_version_branch, :provider_version_branch] => :line

        def initialize line, options = {}
          @line = line
          @options = options
          @overwritten = false # true if the pact was revised and this revision is no longer the latest
        end

        def provider_name
          @line.provider_name
        end

        def provider_name_url
          hal_browser_url(pacticipant_url_from_params({ pacticipant_name: provider_name }, base_url), base_url)
        end

        def consumer_name
          @line.consumer_name
        end

        def consumer_name_url
          hal_browser_url(pacticipant_url_from_params({ pacticipant_name: consumer_name }, base_url), base_url)
        end

        def pact_version_sha
          @line.pact_version_sha
        end

        def pact_version_sha_message
          "The highlighted pact(s) have content that has a SHA of #{pact_version_sha}"
        end

        # verification number, used in verification_url method
        def number
          @line.verification_number
        end

        def pact_revision_number
          @line.pact_revision_number
        end

        def consumer_version_id
          @line.consumer_version_id
        end

        def provider_version_id
          @line.provider_version_id
        end

        def consumer_version_number
          @line.consumer_version_number
        end

        def display_consumer_version_number
          PactBroker::Versions::AbbreviateNumber.call(consumer_version_number)
        end

        def consumer_version_number_url
          params = { pacticipant_name: consumer_name, version_number: consumer_version_number }
          hal_browser_url(version_url_from_params(params, base_url), base_url)
        end

        def consumer_version_order
          @line.consumer_version_order
        end

        def provider_version_number
          @line.provider_version_number
        end

        def display_provider_version_number
          PactBroker::Versions::AbbreviateNumber.call(provider_version_number)
        end

        def provider_version_number_url
          params = { pacticipant_name: provider_name, version_number: provider_version_number }
          hal_browser_url(version_url_from_params(params, base_url), base_url)
        end

        def provider_version_order
          if @line.verification_executed_at
            @line.verification_executed_at.to_time.to_i
          else
            0
          end
        end

        def consumer_version_branch_tooltip
          branch_tooltip(consumer_name, consumer_version_branch, consumer_version_latest_for_branch?)
        end

        def consumer_version_latest_for_branch?
          @line.consumer_version.latest_for_branch?
        end

        def provider_version_branch_tooltip
          branch_tooltip(provider_name, provider_version_branch, provider_version_latest_for_branch?)
        end

        def provider_version_latest_for_branch?
          @line.provider_version.latest_for_branch?
        end

        def latest_consumer_version_tags
          @line.consumer_version_tags
            .select(&:latest)
            .sort_by(&:created_at)
            .collect{ | tag | MatrixTag.new(tag.to_hash.merge(pacticipant_name: consumer_name, version_number: consumer_version_number)) }
        end

        def other_consumer_version_tags
          @line.consumer_version_tags
            .reject(&:latest)
            .sort_by(&:created_at)
            .collect{ | tag | MatrixTag.new(tag.to_hash.merge(pacticipant_name: consumer_name, version_number: consumer_version_number)) }
        end

        def consumer_deployed_versions
          @line.consumer_version.current_deployed_versions.collect do | deployed_version |
            MatrixDeployedVersion.new(deployed_version)
          end
        end

        def provider_deployed_versions
          (@line.provider_version&.current_deployed_versions || []).collect do | deployed_version |
            MatrixDeployedVersion.new(deployed_version)
          end
        end

        def latest_provider_version_tags
          @line.provider_version_tags
            .select(&:latest)
            .sort_by(&:created_at)
            .collect{ | tag | MatrixTag.new(tag.to_hash.merge(pacticipant_name: provider_name, version_number: provider_version_number)) }
        end

        def other_provider_version_tags
          @line.provider_version_tags
            .reject(&:latest)
            .sort_by(&:created_at)
            .collect{ | tag | MatrixTag.new(tag.to_hash.merge(pacticipant_name: provider_name, version_number: provider_version_number)) }
        end

        def orderable_fields
          [@line.last_action_date, @line.pact_created_at]
        end

        def <=> other
          (orderable_fields <=> other.orderable_fields) * -1
        end

        def verification_status
          if @line.verification_executed_at
            DateHelper.distance_of_time_in_words(@line.verification_executed_at, DateTime.now) + " ago"
          else
            ""
          end
          # case @line.success
          #   when true then "Verified"
          #   when false then "Failed"
          #   else ''
          # end
        end

        def verification_status_url
          hal_browser_url(verification_url(self, base_url), base_url)
        end

        def pact_publication_date
          relative_date(@line.pact_created_at)
        end

        def pact_publication_date_url
          pact_url(base_url, @line)
        end

        def relative_date date
          DateHelper.distance_of_time_in_words(date, DateTime.now) + " ago"
        end

        def pact_published_order
          @line.pact_created_at.to_time.to_i
        end

        def verification_status_class
          case @line.success
            when true then "table-success"
            when false then "table-danger"
            else ""
          end
        end

        def overwritten?
          @overwritten
        end

        def overwritten= overwritten
          @overwritten = overwritten
        end

        def pre_verified_message
          if @line.verification_executed_at && @line.pact_created_at > @line.verification_executed_at
            message("messages.matrix.pre_verified")
          end
        end

        def base_url
          @options[:base_url]
        end

        private

        attr_reader :line

        def branch_tooltip(pacticipant_name, branch, latest)
          if latest
            "This is the latest version of #{pacticipant_name} from branch \"#{branch}\"."
          else
            "A more recent version of #{pacticipant_name} from branch \"#{branch}\" exists."
          end
        end
      end
    end
  end
end
