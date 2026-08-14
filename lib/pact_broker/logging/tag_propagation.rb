# frozen_string_literal: true
require "semantic_logger"

module PactBroker
  module Logging
    # Carries the logging context across an execution boundary.
    #
    # SemanticLogger's named tags are thread local and scoped to a block, so they
    # are gone by the time a rack.after_reply callback or a background job runs.
    # Capture them where the context exists, and restore them where the work
    # happens.
    #
    # Note that trace context is deliberately not captured: it is contributed by
    # a context provider at log time, so a job that runs long after the request
    # reports whatever span is actually active rather than resurrecting a stale
    # trace id.
    module TagPropagation
      # SemanticLogger.named_tags already returns a copy, so this is a snapshot.
      def self.capture
        SemanticLogger.named_tags
      end

      def self.with(tags, &block)
        if tags.nil? || tags.empty?
          block.call
        else
          SemanticLogger.tagged(tags, &block)
        end
      end
    end
  end
end
