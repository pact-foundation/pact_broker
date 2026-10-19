require "pact_broker/logging/context/trace_context"

module PactBroker
  module Logging
    module Context
      describe TraceContext do
        describe ".call" do
          context "when OpenTelemetry is not loaded" do
            it "returns an empty hash" do
              allow(TraceContext).to receive(:otel_loaded?).and_return(false)

              expect(TraceContext.call).to eq({})
            end
          end

          context "when there is no valid span" do
            it "returns an empty hash" do
              span_context = double("span context", valid?: false)
              allow(TraceContext).to receive(:otel_loaded?).and_return(true)
              allow(TraceContext).to receive(:current_span_context).and_return(span_context)

              expect(TraceContext.call).to eq({})
            end
          end

          context "when there is a valid sampled span" do
            it "returns the correlation fields" do
              span_context = double(
                "span context",
                valid?: true,
                hex_trace_id: "0af7651916cd43dd8448eb211c80319c",
                hex_span_id: "b7ad6b7169203331",
                trace_flags: double("trace flags", sampled?: true)
              )
              allow(TraceContext).to receive(:otel_loaded?).and_return(true)
              allow(TraceContext).to receive(:current_span_context).and_return(span_context)

              expect(TraceContext.call).to eq(
                trace_id: "0af7651916cd43dd8448eb211c80319c",
                span_id: "b7ad6b7169203331",
                trace_flags: "01"
              )
            end
          end

          context "when the span is not sampled" do
            it "reports trace_flags as 00" do
              span_context = double(
                "span context",
                valid?: true,
                hex_trace_id: "0af7651916cd43dd8448eb211c80319c",
                hex_span_id: "b7ad6b7169203331",
                trace_flags: double("trace flags", sampled?: false)
              )
              allow(TraceContext).to receive(:otel_loaded?).and_return(true)
              allow(TraceContext).to receive(:current_span_context).and_return(span_context)

              expect(TraceContext.call[:trace_flags]).to eq "00"
            end
          end

          context "when OpenTelemetry raises" do
            it "returns an empty hash rather than breaking logging" do
              allow(TraceContext).to receive(:otel_loaded?).and_return(true)
              allow(TraceContext).to receive(:current_span_context).and_raise("otel is unhappy")

              expect(TraceContext.call).to eq({})
            end
          end
        end

        describe ".otel_loaded?" do
          context "when the OpenTelemetry gems are not loaded" do
            it "is false" do
              hide_const("OpenTelemetry")

              expect(TraceContext.otel_loaded?).to be false
            end
          end

          context "when the OpenTelemetry gems are loaded" do
            it "is true" do
              stub_const("OpenTelemetry::Trace", Module.new)

              expect(TraceContext.otel_loaded?).to be true
            end
          end
        end

        describe ".current_span_context" do
          it "returns the context of the currently active span" do
            span_context = double("span context")
            stub_const("OpenTelemetry::Trace", double("Trace", current_span: double("span", context: span_context)))

            expect(TraceContext.current_span_context).to be span_context
          end
        end
      end
    end
  end
end
