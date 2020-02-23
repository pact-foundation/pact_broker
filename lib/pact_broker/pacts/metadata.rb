module PactBroker
  module Pacts
    module Metadata
      extend self

      # When verifying a pact at /.../latest/TAG, this stores the
      # tag and the current consumer version number in the
      # metadata parameter of the URL for publishing the verification results.
      # This is part of ensuring that verification results webhooks
      # go back to the correct consumer version number (eg for git statuses)
      def build_metadata_for_latest_pact(pact, selection_parameters)
        if selection_parameters[:tag]
          {
            consumer_version_tags: selection_parameters[:tag],
            consumer_version_number: pact.consumer_version_number
          }
        else
          {
            consumer_version_number: pact.consumer_version_number
          }
        end
      end

      # When a pact is published, and a webhook is triggered, this stores
      # the current tags and consumer version number in the metadata parameter of the
      # pact version URL that is made available in the webhook template
      # parameters. This is part of ensuring that verification results webhooks
      # go back to the correct consumer version number (eg for git statuses)
      def build_metadata_for_webhook_triggered_by_pact_publication(pact)
        {
          consumer_version_number: pact.consumer_version_number,
          consumer_version_tags: pact.consumer_version_tag_names
        }
      end
    end
  end
end
