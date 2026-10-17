# frozen_string_literal: true
require "pact_broker/logging/context"

module PactBroker
  module Logging
    module Context
      # Adds the standard OpenTelemetry log correlation fields when a valid span
      # is active. Degrades to contributing nothing when the OpenTelemetry gems
      # are not loaded, so it is safe for the open source Pact Broker, where they
      # are an optional dependency.
      #
      # This is deliberately a context provider rather than formatter logic, so
      # that correlation reaches every appender and formatter, not only JSON.
      module TraceContext
        NO_CONTEXT = {}.freeze

        def self.call
          return NO_CONTEXT unless otel_loaded?

          span_context = current_span_context
          return NO_CONTEXT unless span_context.valid?

          {
            trace_id: span_context.hex_trace_id,
            span_id: span_context.hex_span_id,
            trace_flags: span_context.trace_flags.sampled? ? "01" : "00"
          }
        rescue StandardError
          NO_CONTEXT
        end

        def self.otel_loaded?
          defined?(::OpenTelemetry::Trace) ? true : false
        end

        def self.current_span_context
          ::OpenTelemetry::Trace.current_span.context
        end
      end
    end
  end
end
