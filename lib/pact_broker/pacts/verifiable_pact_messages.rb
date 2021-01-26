require 'forwardable'

module PactBroker
  module Pacts
    class VerifiablePactMessages
      extend Forwardable

      READ_MORE_PENDING = "Read more at https://pact.io/pending"
      READ_MORE_WIP = "Read more at https://pact.io/wip"

      delegate [:consumer_name, :provider_name, :consumer_version_number, :pending_provider_tags, :non_pending_provider_tags, :pending?, :wip?] => :verifiable_pact

      def initialize(verifiable_pact, pact_version_url)
        @verifiable_pact = verifiable_pact
        @pact_version_url = pact_version_url
      end

      def pact_description
        position_descs = if head_consumer_tags.empty?
          ["latest"]
        else
          head_consumer_tags.collect { | tag | "latest #{tag}"}
        end

        "Pact between #{consumer_name} and #{provider_name}, consumer version #{consumer_version_number}, #{position_descs.join(",")}"
      end

      def inclusion_reason
        version_text = head_consumer_tags.size == 1 ? "version" : "versions"
        if wip?
          # WIP pacts will always have tags, because it is part of the definition of being a WIP pact
          "The pact at #{pact_version_url} is being verified because it is a 'work in progress' pact (ie. it is the pact for the latest #{version_text} of #{consumer_name} tagged with #{joined_head_consumer_tags} and is still in pending state). #{READ_MORE_WIP}"
        else
          criteria_or_criterion = selectors.size > 1 ? "criteria" : "criterion"
          "The pact at #{pact_version_url} is being verified because it matches the following configured selection #{criteria_or_criterion}: #{selector_descriptions}#{same_content_note}"
        end
      end

      def pending_reason
        if pending?
          "This pact is in pending state for this version of #{provider_name} because a successful verification result for #{pending_provider_tags_description("a")} has not yet been published. If this verification fails, it will not cause the overall build to fail. #{READ_MORE_PENDING}"
        else
          "This pact has previously been successfully verified by #{non_pending_provider_tags_description}. If this verification fails, it will fail the build. #{READ_MORE_PENDING}"
        end
      end

      def verification_success_true_published_false
        if pending?
          "This pact is still in pending state for #{pending_provider_tags_description} as the successful verification results #{with_these_tags}have not yet been published."
        end
      end

      def verification_success_true_published_true
        if pending?
          "This pact is no longer in pending state for #{pending_provider_tags_description}, as a successful verification result #{with_these_tags}has been published. If a verification for a version of #{provider_name} #{with_these_tags}fails in the future, it will fail the build. #{READ_MORE_PENDING}"
        end
      end

      def verification_success_false_published_false
        if pending?
          "This pact is still in pending state for #{pending_provider_tags_description} as a successful verification result #{with_these_tags}has not yet been published"
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

      def join(list, last_joiner = " and ")
        quoted_list = list.collect { | tag | "'#{tag}'" }
        comma_joined = quoted_list[0..-3] || []
        and_joined =  quoted_list[-2..-1] || quoted_list
        if comma_joined.any?
          "#{comma_joined.join(', ')}, #{and_joined.join(last_joiner)}"
        else
          and_joined.join(last_joiner)
        end
      end

      def joined_head_consumer_tags
        join(head_consumer_tags) + same_content_note
      end

      def same_content_note
        case selectors.size
        when 1 then ""
        when 2 then " (both have the same content)"
        else " (all have the same content)"
        end
      end

      def pending_provider_tags_description(any_or_a = "any")
        case pending_provider_tags.size
        when 0 then provider_name
        when 1 then "#{any_or_a} version of #{provider_name} with tag '#{pending_provider_tags.first}'"
        else "#{any_or_a} versions of #{provider_name} with tag #{join(pending_provider_tags)}"
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

      def selector_descriptions
        selectors.sort.collect do | selector |
          selector_description(selector)
        end.join(", ")
      end

      def selector_description selector
        if selector.overall_latest?
          consumer_label = selector.consumer ? selector.consumer : 'a consumer'
          "latest pact between #{consumer_label} and #{provider_name}"
        elsif selector.latest_for_tag?
          version_label = selector.consumer ? "version of #{selector.consumer}" : "consumer version"
          if selector.fallback_tag?
            "latest pact for a #{version_label} tagged '#{selector.fallback_tag}' (fallback tag used as no pact was found with tag '#{selector.tag}')"
          else
            "latest pact for a #{version_label} tagged '#{selector.tag}'"
          end
        elsif selector.all_for_tag_and_consumer?
          "pacts for all #{selector.consumer} versions tagged '#{selector.tag}'"
        elsif selector.all_for_tag?
          "pacts for all consumer versions tagged '#{selector.tag}'"
        else
          selector.to_json
        end
      end

      def short_selector_descriptions
        selectors.collect{ | selector | short_selector_description(selector) }.join(", ")
      end

      # this is used by Pact Go to create the test method name, so needs to be concise
      def short_selector_description selector
        if selector.overall_latest?
          "latest"
        elsif selector.latest_for_tag?
          if selector.fallback_tag?
            "latest #{selector.fallback_tag}"
          else
            "latest #{selector.tag}"
          end
        elsif selector.all_for_tag_and_consumer?
          "one of #{selector.consumer} #{selector.tag}"
        elsif selector.tag
          "one of #{selector.tag}"
        else
          selector.to_json
        end
      end

      def selectors
        verifiable_pact.selectors
      end
    end
  end
end
