module PactBroker
  module Pacts
    module Metadata
      extend self

      MAPPINGS = [
        [:consumer_version_tags, "cvt"],
        [:consumer_version_number, "cvn"], # for old urls and build_metadata_for_consumer_version_number
        [:consumer_version_id, "cv"],
        [:wip, "w"],
        [:pending, "p"],
        [:consumer_version_selectors, "s"],
        [:tag, "t"],
        [:branch, "b"],
        [:latest, "l"]
      ]

      # When verifying a pact at /.../latest/TAG, this stores the
      # tag and the current consumer version number in the
      # metadata parameter of the URL for publishing the verification results.
      # This is part of ensuring that verification results webhooks
      # go back to the correct consumer version number (eg for git statuses)
      def build_metadata_for_latest_pact(pact, selection_parameters)
        if selection_parameters[:tag]
          {
            "cvt" => [selection_parameters[:tag]],
            "cv" => pact.consumer_version.id
          }
        else
          {
            "cv" => pact.consumer_version.id
          }
        end
      end

      def build_metadata_for_consumer_version_number(consumer_version_number)
        {
          "cvn" => consumer_version_number
        }
      end

      # When a pact is published, and a webhook is triggered, this stores
      # the current tags and consumer version number in the metadata parameter of the
      # pact version URL that is made available in the webhook template
      # parameters. This is part of ensuring that verification results webhooks
      # go back to the correct consumer version number (eg for git statuses)
      def build_metadata_for_webhook_triggered_by_pact_publication(pact)
        metadata = {
          "cvn" => pact.consumer_version_number,
          "cvt" => pact.consumer_version_tag_names
        }
        metadata["w"] = "true"
        metadata
      end

      def build_metadata_for_pact_for_verification(verifiable_pact)
        # todo put in tags
        if verifiable_pact.wip
          {
            "w" => true
          }
        else

          # TODO support deployed and released
          {
            "s" => verifiable_pact.selectors.collect do | selector |
              {
                "b" => selector.branch,
                "t" => selector.tag,
                "l" => selector.latest,
                "cv" => selector.consumer_version.id
              }.compact
            end,
            "p" => verifiable_pact.pending?
          }.compact
        end
      end

      def parse_metadata(metadata)
        parse_object(metadata)
      end

      def parse_object(object)
        case object
        when Hash then parse_hash(object)
        when Array then object.collect{|i| parse_object(i) }
        else object
        end
      end

      def parse_hash(hash)
        require "pact_broker/domain/version" # can't load this before the db models
        hash.each_with_object({}) do | (key, value), new_hash |
          long_key = MAPPINGS.find{ |mapping| mapping.last == key }&.first
          if long_key == :consumer_version_id
            new_hash[:consumer_version_number] = PactBroker::Domain::Version.find(id: value.to_i)&.number
          else
            new_hash[long_key || key] = parse_object(value)
          end
        end
      end
    end
  end
end
