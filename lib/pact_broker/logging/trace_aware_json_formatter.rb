require "semantic_logger"
require "semantic_logger/formatters/json"

module PactBroker
  module Logging
    # A JSON log formatter that adds the standard OpenTelemetry log-correlation
    # fields (trace_id, span_id, trace_flags) when a valid span is active.
    # Degrades to plain JSON when OTel is not loaded or there is no active span,
    # so it is safe for the open-source Pact Broker.
    class TraceAwareJsonFormatter < SemanticLogger::Formatters::Json
      def call(log, logger)
        json = super
        context = otel_trace_context
        return json if context.empty?

        # `hash` was populated by Raw#call during `super`; reuse it.
        hash.merge(context).to_json
      end

      private

      def otel_trace_context
        return {} unless defined?(OpenTelemetry::Trace)

        span_context = OpenTelemetry::Trace.current_span.context
        return {} unless span_context.valid?

        {
          trace_id: span_context.hex_trace_id,
          span_id: span_context.hex_span_id,
          trace_flags: span_context.trace_flags.sampled? ? "01" : "00"
        }
      rescue StandardError
        {}
      end
    end
  end
end
