require "pact_broker/logging/trace_aware_json_formatter"
require "json"

module PactBroker
  module Logging
    describe TraceAwareJsonFormatter do
      let(:formatter) { TraceAwareJsonFormatter.new }
      let(:appender) do
        double("appender", host: "localhost", application: "test_app", environment: "test")
      end
      let(:log) do
        log = SemanticLogger::Log.new("test", :info)
        log.message = "hello"
        log
      end
      subject { JSON.parse(formatter.call(log, appender)) }

      context "when OTel is not loaded" do
        before { allow(formatter).to receive(:otel_trace_context).and_return({}) }

        it "emits plain JSON with the message and no trace fields" do
          expect(subject["message"]).to eq "hello"
          expect(subject).to_not have_key("trace_id")
          expect(subject).to_not have_key("span_id")
        end
      end

      context "when a valid active span exists" do
        before do
          allow(formatter).to receive(:otel_trace_context).and_return(
            trace_id: "0af7651916cd43dd8448eb211c80319c",
            span_id: "b7ad6b7169203331",
            trace_flags: "01"
          )
        end

        it "includes the OTel correlation fields alongside the message" do
          expect(subject["message"]).to eq "hello"
          expect(subject["trace_id"]).to eq "0af7651916cd43dd8448eb211c80319c"
          expect(subject["span_id"]).to eq "b7ad6b7169203331"
          expect(subject["trace_flags"]).to eq "01"
        end
      end
    end
  end
end
