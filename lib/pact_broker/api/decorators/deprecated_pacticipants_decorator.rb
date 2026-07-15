require "roar/json/hal"
require_relative "embedded_version_decorator"
require_relative "pagination_links"

module PactBroker
  module Api
    module Decorators
      # TODO deprecate this - breaking change for v 3.0
      class DeprecatedPacticipantsDecorator < PacticipantsDecorator
        def to_hash(options)
          embedded_pacticipant_hash = super
          non_embedded_pacticipant_hash = NonEmbeddedPacticipantCollectionDecorator.new(represented).to_hash(options)
          embedded_pacticipant_hash.merge(non_embedded_pacticipant_hash)
        end
      end
    end
  end
end
