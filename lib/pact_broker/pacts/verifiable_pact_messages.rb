require "forwardable"
require "pact_broker/messages"

module PactBroker
  module Pacts
    class VerifiablePactMessages
      extend Forwardable
      include PactBroker::Messages

      READ_MORE_PENDING = "Read more at https://docs.pact.io/go/pending"
      READ_MORE_WIP = "Read more at https://docs.pact.io/go/wip"

      delegate [:consumer_name, :provider_name, :consumer_version_number, :pending_provider_tags, :non_pending_provider_tags, :provider_branch, :pending?, :wip?] => :verifiable_pact

      def initialize(verifiable_pact, pact_version_url)
        @verifiable_pact = verifiable_pact
        @pact_version_url = pact_version_url
      end

      def pact_description
        position_descs = if head_consumer_tags.empty? && branches.empty?
                           ["latest"]
                         else
                           head_consumer_tags.collect { |tag| "latest with tag #{tag}" } + branches.collect{ |branch| "latest from branch #{branch}" }
                         end

        "Pact between #{consumer_name} and #{provider_name}, consumer version #{consumer_version_number}, #{position_descs.join(", ")}"
      end

      def inclusion_reason
        version_text = head_consumer_tags.size == 1 || branches.size == 1 ? "version" : "versions"
        if wip?
          # WIP pacts will always have tags, because it is part of the definition of being a WIP pact
          "The pact at #{pact_version_url} is being verified because it is a 'work in progress' pact (ie. it is the pact for the latest #{version_text} of #{consumer_name} #{joined_head_consumer_tags_and_branches} and it has not yet been successfully verified by #{pending_provider_branch_or_tags_description("a")} when the pact's application version was explicitly specified in the consumer version selectors). #{READ_MORE_WIP}"
        else
          criteria_or_criterion = selectors.size > 1 ? "criteria" : "criterion"
          version_or_versions = pluralize("the consumer version", selectors.size)
          "The pact at #{pact_version_url} is being verified because the pact content belongs to #{version_or_versions} matching the following #{criteria_or_criterion}:\n#{selector_descriptions}"
        end
      end

      def pending_reason
        if pending? && wip?
          "This pact is in pending state for this version of #{provider_name} because it was included as a 'work in progress' pact. If this verification fails, it will not cause the overall build to fail. #{READ_MORE_PENDING}"
        elsif pending?
          "This pact is in pending state for this version of #{provider_name} because a successful verification result for #{pending_provider_branch_or_tags_description("a")} has not yet been published. If this verification fails, it will not cause the overall build to fail. #{READ_MORE_PENDING}"
        else
          "This pact has previously been successfully verified by #{non_pending_provider_branch_or_tags_description}. If this verification fails, it will fail the build. #{READ_MORE_PENDING}"
        end
      end

      def verification_success_true_published_false
        if pending?
          "This pact is still in pending state for #{pending_provider_branch_or_tags_description} as the successful verification results #{with_these_tags}have not yet been published."
        end
      end

      def verification_success_true_published_true
        if pending?
          "This pact is no longer in pending state for #{pending_provider_branch_or_tags_description}, as a successful verification result #{with_these_tags}has been published. If a verification for a version of #{provider_name} #{with_these_tags}fails in the future, it will fail the build. #{READ_MORE_PENDING}"
        end
      end

      def verification_success_false_published_false
        if pending?
          "This pact is still in pending state for #{pending_provider_branch_or_tags_description} as a successful verification result #{with_these_tags}has not yet been published"
        end
      end

      def verification_success_false_published_true
        verification_success_false_published_false
      end

      def pact_version_short_description
        short_selector_descriptions
      end

      private

      attr_reader :verifiable_pact, :pact_version_url

      def consumer_main_branch
        verifiable_pact.consumer.main_branch
      end

      def join(list, last_joiner = " and ")
        join_unquoted(list.collect { | word | "'#{word}'" }, last_joiner)
      end

      def join_unquoted(list, last_joiner = " and ")
        comma_joined = list[0..-3] || []
        and_joined =  list[-2..-1] || list
        if comma_joined.any?
          "#{comma_joined.join(', ')}, #{and_joined.join(last_joiner)}"
        else
          and_joined.join(last_joiner)
        end
      end

      def joined_head_consumer_tags_and_branches
        parts = []
        parts << "from #{branches.size == 1 ? "branch" : "branches"} #{join(branches)}" if branches.any?
        parts << "tagged with #{join(head_consumer_tags)}" if head_consumer_tags.any?
        parts.join(" and ") + same_content_note
      end

      def same_content_note
        case selectors.size
        when 1 then ""
        when 2 then " (both have the same content)"
        else " (all have the same content)"
        end
      end

      def pending_provider_branch_or_tags_description(any_or_a = "any")
        if provider_branch
          pending_provider_branch_description(any_or_a)
        else
          pending_provider_tags_description(any_or_a)
        end
      end

      def pending_provider_branch_description(any_or_a)
        "#{any_or_a} version of #{provider_name} from branch '#{provider_branch}'"
      end

      def pending_provider_tags_description(any_or_a)
        case pending_provider_tags.size
        when 0 then provider_name
        when 1 then "#{any_or_a} version of #{provider_name} with tag '#{pending_provider_tags.first}'"
        else "#{any_or_a} versions of #{provider_name} with tag #{join(pending_provider_tags)}"
        end
      end

      def non_pending_provider_branch_or_tags_description
        if provider_branch
          "a version of #{provider_name} from branch '#{provider_branch}'"
        else
          non_pending_provider_tags_description
        end
      end

      def non_pending_provider_tags_description
        case non_pending_provider_tags.size
        when 0 then provider_name
        when 1 then "a version of #{provider_name} with tag '#{non_pending_provider_tags.first}'"
        else "a version of #{provider_name} with tag #{join(non_pending_provider_tags)}"
        end
      end

      def with_these_tags
        case pending_provider_tags.size
        when 0 then ""
        when 1 then "with this tag "
        else "with these tags "
        end
      end

      def head_consumer_tags
        selectors.tag_names_of_selectors_for_latest_pacts
      end

      def branches
        selectors.branches_of_selectors_for_latest_pacts
      end

      def selector_descriptions
        selectors.sort.group_by(&:type).values.flat_map do | selectors |
          selectors_descriptions(selectors)
        end.collect{ |description| "    * #{description}" }
          .join("\n")
      end

      def selectors_descriptions(selectors)
        if selectors.first.currently_deployed?
          currently_deployed_selectors_description(selectors)
        elsif selectors.first.currently_supported?
          currently_supported_selectors_description(selectors)
        else
          selectors.collect do | selector |
            selector_description(selector)
          end
        end
      end

      # rubocop: disable Metrics/CyclomaticComplexity
      # rubocop: disable Metrics/MethodLength
      def selector_description selector
        description = if selector.overall_latest?
                        consumer_label = selector.consumer ? selector.consumer : "a consumer"
                        "latest version of #{consumer_label} that has a pact with #{provider_name}"
                      elsif selector.latest_for_tag?
                        version_label = selector.consumer ? "version of #{selector.consumer}" : "version"
                        if selector.fallback_tag?
                          "latest #{version_label} tagged '#{selector.fallback_tag}' (fallback tag used as no pact was found with tag '#{selector.tag}')"
                        else
                          "latest #{version_label} tagged '#{selector.tag}'"
                        end
                      elsif selector.latest_for_main_branch?
                        version_label = selector.consumer ? "version of #{selector.consumer}" : "version"
                        "latest #{version_label} from the main branch '#{consumer_main_branch}'"
                      elsif selector.latest_for_branch?
                        version_label = selector.consumer ? "version of #{selector.consumer}" : "version"
                        if selector.fallback_branch?
                          "latest #{version_label} from branch '#{selector.fallback_branch}' (fallback branch used as no pact was found from branch '#{selector.branch}')"
                        else
                          "latest #{version_label} from branch '#{selector.branch}'"
                        end
                      elsif selector.all_for_tag_and_consumer?
                        "all #{selector.consumer} versions tagged '#{selector.tag}'"
                      elsif selector.all_for_tag?
                        "all consumer versions tagged '#{selector.tag}'"
                      elsif selector.in_environment?
                        consumer_label = selector.consumer ? selector.consumer : "a consumer"
                        "#{consumer_label} version in environment #{selector.environment.name}"
                      else
                        selector.to_json
                      end
        "#{description} (#{selector.consumer_version.number})"
      end
      # rubocop: enable Metrics/CyclomaticComplexity
      # rubocop: enable Metrics/MethodLength

      def currently_deployed_selectors_description(selectors)
        selectors.group_by(&:consumer).flat_map do | consumer_name, consumer_selectors |
          display_name = consumer_name ? "version(s) of #{consumer_name}" : "consumer version(s)"
          environments_and_versions = consumer_selectors.collect{ | selector | "#{selector.environment.name} (#{selector.consumer_version.number})" }
          "#{display_name} currently deployed to #{join_unquoted(environments_and_versions)}"
        end
      end

      def currently_supported_selectors_description(selectors)
        selectors.group_by(&:consumer).flat_map do | consumer_name, consumer_selectors |
          display_name = consumer_name ? "version(s) of #{consumer_name}" : "consumer version(s)"
          environments_and_versions = consumer_selectors.collect{ | selector | "#{selector.environment.name} (#{selector.consumer_version.number})" }
          "#{display_name} released and supported in #{join_unquoted(environments_and_versions)}"
        end
      end

      def short_selector_descriptions
        selectors.collect{ | selector | short_selector_description(selector) }.join(", ")
      end

      # rubocop: disable Metrics/CyclomaticComplexity
      # this is used by Pact Go to create the test method name, so needs to be concise
      def short_selector_description selector
        if selector.overall_latest?
          "latest"
        elsif selector.latest_for_tag?
          if selector.fallback_tag?
            "latest with tag #{selector.fallback_tag}"
          else
            "latest with tag #{selector.tag}"
          end
        elsif selector.latest_for_main_branch?
          "latest from main branch"
        elsif selector.latest_for_branch?
          if selector.fallback_branch?
            "latest from branch #{selector.fallback_branch}"
          else
            "latest from branch #{selector.branch}"
          end
        elsif selector.all_for_tag_and_consumer?
          "one of #{selector.consumer} #{selector.tag}"
        elsif selector.tag
          "one of #{selector.tag}"
        elsif selector.currently_deployed?
          "deployed to #{selector.environment.name}"
        elsif selector.currently_supported?
          "released in #{selector.environment.name}"
        else
          selector.to_json
        end
      end
      # rubocop: enable Metrics/CyclomaticComplexity

      def selectors
        verifiable_pact.selectors
      end
    end
  end
end
