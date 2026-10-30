require "pact_broker/api/decorators/base_decorator"
require "pact_broker/api/decorators/timestamps"

module PactBroker
  module Api
    module Decorators
      class PublishContractDecorator < BaseDecorator
        camelize_property_names

        property :consumer_name
        property :provider_name
        property :specification
        property :content_type
        property :decoded_content, setter: -> (fragment:, represented:, user_options:, doc:, **) {
          represented.decoded_content = fragment
          # Set the pact version sha when we set the content, reusing the content that has already been
          # parsed in the resource, as parsing very large pacts is expensive
          represented.pact_version_sha = user_options.fetch(:sha_generator).call(fragment, parsed_content: doc["decodedParsedContent"])
        }
        property :on_conflict, default: "overwrite"

      end
    end
  end
end
