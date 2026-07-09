require "pact_broker/logging/open_telemetry_appender_setup"
require "pact_broker/config/runtime_configuration"

module PactBroker
  module Logging
    describe OpenTelemetryAppenderSetup do
      let(:runtime_configuration) do
        config = PactBroker::Config::RuntimeConfiguration.new
        config.log_otel_enabled = otel_enabled
        config
      end
      let(:otel_enabled) { :auto }
      let(:setup) { OpenTelemetryAppenderSetup.new(runtime_configuration) }
      let(:fake_appender) { double("otel appender") }

      before do
        allow(SemanticLogger).to receive(:add_appender).and_return(fake_appender)
        allow(SemanticLogger).to receive(:appenders).and_return([])
        allow(setup).to receive(:otel_available?).and_return(true)
        allow(setup).to receive(:otel_provider_configured?).and_return(true)
      end

      context "when :auto, available, provider configured" do
        it "adds the open_telemetry appender" do
          expect(SemanticLogger).to receive(:add_appender).with(appender: :open_telemetry)
          expect(setup.call).to eq fake_appender
        end
      end

      context "when :auto but not available" do
        before { allow(setup).to receive(:otel_available?).and_return(false) }
        it "adds nothing" do
          expect(SemanticLogger).to_not receive(:add_appender)
          expect(setup.call).to be_nil
        end
      end

      context "when :auto, available, but no provider" do
        before { allow(setup).to receive(:otel_provider_configured?).and_return(false) }
        it "adds nothing" do
          expect(SemanticLogger).to_not receive(:add_appender)
          expect(setup.call).to be_nil
        end
      end

      context "when true but not available" do
        let(:otel_enabled) { true }
        before { allow(setup).to receive(:otel_available?).and_return(false) }
        it "raises a ConfigurationError" do
          expect { setup.call }.to raise_error(PactBroker::ConfigurationError, /opentelemetry-logs-sdk/)
        end
      end

      context "when true, available, but no provider" do
        let(:otel_enabled) { true }
        before { allow(setup).to receive(:otel_provider_configured?).and_return(false) }
        it "adds the appender anyway" do
          expect(SemanticLogger).to receive(:add_appender).with(appender: :open_telemetry)
          expect(setup.call).to eq fake_appender
        end
      end

      context "when false, even if available" do
        let(:otel_enabled) { false }
        it "adds nothing" do
          expect(SemanticLogger).to_not receive(:add_appender)
          expect(setup.call).to be_nil
        end
      end

      context "idempotency" do
        it "does not add a second appender when one already exists" do
          existing = double("existing otel appender")
          allow(setup).to receive(:existing_otel_appender).and_return(existing)
          expect(SemanticLogger).to_not receive(:add_appender)
          expect(setup.call).to eq existing
        end
      end
    end
  end
end
