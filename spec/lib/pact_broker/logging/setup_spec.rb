require "pact_broker/logging/setup"
require "pact_broker/config/runtime_configuration"

module PactBroker
  module Logging
    describe Setup do
      let(:runtime_configuration) do
        config = PactBroker::Config::RuntimeConfiguration.new
        config.log_appenders = log_appenders
        config.log_level = "warn"
        config
      end
      let(:log_appenders) { [{ stream: :stdout, format: :json }] }
      let(:appender) { double("appender") }

      before do
        allow(SemanticLogger).to receive(:add_appender).and_return(appender)
        allow(SemanticLogger).to receive(:remove_appender)
        allow(SemanticLogger).to receive(:on_log)
        allow(SemanticLogger).to receive(:default_level=)
        allow(SemanticLogger).to receive(:application=)
        allow(SemanticLogger).to receive(:environment=)
        Setup.reset!
        Context.reset
      end

      after do
        Setup.reset!
        Context.reset
      end

      it "sets the default level from the configuration" do
        expect(SemanticLogger).to receive(:default_level=).with(:warn)
        Setup.call(runtime_configuration)
      end

      it "sets the application name, so JSON logs identify the service" do
        expect(SemanticLogger).to receive(:application=).with("pact-broker")
        Setup.call(runtime_configuration)
      end

      it "sets the environment when one is configured" do
        runtime_configuration.log_environment = "production"
        expect(SemanticLogger).to receive(:environment=).with("production")
        Setup.call(runtime_configuration)
      end

      it "does not set the environment when none is configured" do
        expect(SemanticLogger).to_not receive(:environment=)
        Setup.call(runtime_configuration)
      end

      it "adds an appender per entry and returns them" do
        expect(SemanticLogger).to receive(:add_appender).once
        expect(Setup.call(runtime_configuration)).to eq [appender]
      end

      it "installs the context pipeline as a constant, so repeated installs are no-ops" do
        expect(SemanticLogger).to receive(:on_log).with(Context)
        Setup.call(runtime_configuration)
      end

      it "registers the trace context provider" do
        Setup.call(runtime_configuration)
        expect(Context.provider_names).to include :trace
      end

      describe "idempotency" do
        it "removes the appenders it added previously rather than accumulating them" do
          Setup.call(runtime_configuration)

          expect(SemanticLogger).to receive(:remove_appender).with(appender)
          Setup.call(runtime_configuration)

          expect(Setup.added_appenders).to eq [appender]
        end

        it "leaves a single trace provider registered" do
          Setup.call(runtime_configuration)
          Setup.call(runtime_configuration)

          expect(Context.provider_names.count { |name| name == :trace }).to eq 1
        end
      end

      describe "warning flush ordering" do
        let(:log_appenders) { nil }
        let(:logger) { double("logger", warn: nil) }

        before do
          allow(runtime_configuration).to receive(:log_setting_explicitly_set?).and_return(false)
          allow(runtime_configuration).to receive(:log_setting_explicitly_set?).with(:log_stream).and_return(true)
          runtime_configuration.log_stream = "stdout"
          allow(SemanticLogger).to receive(:[]).with("pact-broker").and_return(logger)
        end

        it "emits deprecation warnings through the logger, after the appenders exist" do
          expect(SemanticLogger).to receive(:add_appender).at_least(:once).ordered
          expect(logger).to receive(:warn).with(/log_stream.*deprecated/m).ordered

          Setup.call(runtime_configuration)
        end
      end

      describe "when there are no appenders to receive the warnings" do
        let(:log_appenders) { [] }

        before do
          allow(runtime_configuration).to receive(:log_setting_explicitly_set?).and_return(false)
          allow(runtime_configuration).to receive(:log_setting_explicitly_set?).with(:log_stream).and_return(true)
          runtime_configuration.log_stream = "stdout"
        end

        it "falls back to stderr, because an ignored-configuration notice is a diagnostic, not application logging" do
          expect($stderr).to receive(:puts).with(/log_stream.*ignored/m)

          Setup.call(runtime_configuration)
        end
      end

      describe "when an appender cannot be built" do
        let(:log_appenders) { [{ appender: :open_telemetry, enabled: true }] }

        before do
          allow(runtime_configuration).to receive(:log_setting_explicitly_set?).and_return(false)
          allow(runtime_configuration).to receive(:log_setting_explicitly_set?).with(:log_stream).and_return(true)
          runtime_configuration.log_stream = "stdout"
          allow(SemanticLogger).to receive(:add_appender).and_raise(LoadError.new("gem missing"))
        end

        it "prints the buffered warnings to stderr before raising, so the operator sees them" do
          expect($stderr).to receive(:puts).with(/log_stream/).at_least(:once)

          expect { Setup.call(runtime_configuration) }.to raise_error(PactBroker::ConfigurationError)
        end
      end

      describe "shutdown flush" do
        it "registers an at_exit flush only once, because the gem does not provide one" do
          expect(Setup).to receive(:at_exit).once

          Setup.call(runtime_configuration)
          Setup.call(runtime_configuration)
        end
      end
    end
  end
end
