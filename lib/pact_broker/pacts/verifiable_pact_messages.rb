module PactBroker
  module Pacts
    class VerifiablePactMessages
      extend Forwardable

      READ_MORE_PENDING = "Read more at https://pact.io/pending"
      READ_MORE_WIP = "Read more at https://pact.io/wip"

      delegate [:consumer_name, :provider_name, :consumer_version_number, :head_consumer_tags, :pending_provider_tags, :non_pending_provider_tags, :pending?, :wip?] => :verifiable_pact

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
          "The pact at #{pact_version_url} is being verified because it is a 'work in progress' pact (ie. it is the pact for the latest #{version_text} of Foo tagged with #{joined_head_consumer_tags} and is still in pending state). #{READ_MORE_WIP}"
        else
          if head_consumer_tags.any?
            "The pact at #{pact_version_url} is being verified because it is the pact for the latest #{version_text} of Foo tagged with #{joined_head_consumer_tags}"
          else
            "The pact at #{pact_version_url} is being verified because it is the latest pact between #{consumer_name} and #{provider_name}."
          end
        end
      end

      def pending_reason
        if pending?
          "This pact is in pending state because it has not yet been successfully verified by #{pending_provider_tags_description}. If this verification fails, it will not cause the overall build to fail. #{READ_MORE_PENDING}"
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
          "This pact is no longer in pending state for #{pending_provider_tags_description}, as a successful verification result #{with_these_tags}has been published. If a verification for a version with  fails in the future, it will fail the build. #{READ_MORE_PENDING}"
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
        case head_consumer_tags.size
        when 1 then ""
        when 2 then " (both have the same content)"
        else " (all have the same content)"
        end
      end

      def pending_provider_tags_description
        case pending_provider_tags.size
        when 0 then provider_name
        when 1 then "any version of #{provider_name} with tag '#{pending_provider_tags.first}'"
        else "any versions of #{provider_name} with tag #{join(pending_provider_tags)}"
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
    end
  end
end
