# frozen_string_literal: true
require "pact_broker/logging/payload_sanitizer"

module PactBroker
  module Logging
    # Installed as the single SemanticLogger on_log subscriber, so that context
    # enrichment and payload sanitisation happen once per log entry, before the
    # entry fans out to the appenders. Every appender and every formatter
    # therefore sees the same tags.
    #
    # Registered as a constant, not a lambda: SemanticLogger deduplicates
    # subscribers by object identity, so a constant makes installation idempotent.
    #
    # This code must never log. It runs inside the logging pipeline, so logging
    # would recurse. Diagnostics go to $stderr.
    module Context
      extend self

      # Registers a provider of named tags to add to every log entry.
      #
      # name     - Symbol. Re-registering the same name replaces the provider.
      # provider - anything responding to #call, taking no arguments, and
      #            returning a Hash of named tags (or nil to contribute nothing).
      def register_provider(name, provider = nil, &block)
        provider ||= block
        unless provider.respond_to?(:call)
          raise ArgumentError, "A logging context provider must respond to #call"
        end

        mutex.synchronize do
          providers[name] = provider
          warned_providers.delete(name)
        end
        provider
      end

      def deregister_provider(name)
        mutex.synchronize do
          providers.delete(name)
          warned_providers.delete(name)
        end
        nil
      end

      def reset
        mutex.synchronize do
          providers.clear
          warned_providers.clear
        end
        nil
      end

      def provider_names
        providers.keys
      end

      # The maximum level_index (inclusive) considered verbose enough to use
      # PayloadSanitizer::DEBUG_MAX_DEPTH. Matches SemanticLogger::Levels::LEVELS,
      # where trace is 0 and debug is 1.
      DEBUG_LEVEL_INDEX = 1

      # The on_log subscriber entry point.
      def call(log)
        apply_provider_tags(log)
        max_depth = payload_max_depth(log)
        log.message = PayloadSanitizer.call(log.message, max_depth: max_depth) if log.message.is_a?(String)
        log.payload = PayloadSanitizer.call(log.payload, max_depth: max_depth) if log.payload.is_a?(Hash)
        nil
      end

      private

      def payload_max_depth(log)
        if log.level_index <= DEBUG_LEVEL_INDEX
          PayloadSanitizer::DEBUG_MAX_DEPTH
        else
          PayloadSanitizer::MAX_DEPTH
        end
      end

      def apply_provider_tags(log)
        return if providers.empty?

        tags = provider_tags
        return if tags.empty?

        # Existing tags win: an explicit SemanticLogger.tagged value is more
        # specific than a global provider, so it must not be overwritten.
        log.named_tags = tags.merge(log.named_tags || {})
      end

      def provider_tags
        providers.each_with_object({}) do |(name, provider), tags|
          begin
            result = provider.call
            tags.merge!(result) if result.is_a?(Hash)
          rescue StandardError => e
            warn_once(name, e)
          end
        end
      end

      def warn_once(name, error)
        return if warned_providers.include?(name)

        warned_providers << name
        $stderr.puts(
          "WARN: Log context provider #{name.inspect} raised #{error.class}: #{error.message}. " \
          "Its tags will be missing from log entries. Further errors from this provider will not be reported."
        )
      end

      def providers
        @providers ||= {}
      end

      def warned_providers
        @warned_providers ||= []
      end

      def mutex
        @mutex ||= Mutex.new
      end
    end
  end
end
