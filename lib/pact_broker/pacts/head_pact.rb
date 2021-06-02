require "delegate"

# A head pact is the pact for the latest consumer version with the specified tag
# (ignoring later versions that might have the specified tag but no pact)

module PactBroker
  module Pacts
    class HeadPact < SimpleDelegator
      attr_reader :tag, :consumer_version_number

      def initialize(pact, consumer_version_number, tag)
        super(pact)
        @consumer_version_number = consumer_version_number
        @tag = tag
      end

      # The underlying pact publication may well be the overall latest as well, but
      # this row does not know that, as there will be a row with a nil tag
      # if it is the overall latest as well as a row with the
      # tag set, as the data is denormalised in the LatestTaggedPactPublications table.
      def overall_latest?
        tag.nil?
      end

      def pact
        __getobj__()
      end
    end
  end
end
