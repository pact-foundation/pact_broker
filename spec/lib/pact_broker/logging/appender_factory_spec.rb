require "pact_broker/logging/appender_factory"

module PactBroker
  module Logging
    describe AppenderFactory do
      let(:appender) { double("appender") }

      before do
        allow(SemanticLogger).to receive(:add_appender).and_return(appender)
      end

      def build(entry, index: 0, log_dir: "/tmp/logs")
        AppenderFactory.call(entry, index: index, log_dir: log_dir)
      end

      describe "stream sugar" do
        it "maps stdout to $stdout" do
          expect(SemanticLogger).to receive(:add_appender).with(io: $stdout)
          expect(build({ stream: :stdout })).to eq appender
        end

        it "maps stderr to $stderr" do
          expect(SemanticLogger).to receive(:add_appender).with(io: $stderr)
          build({ stream: :stderr })
        end

        it "maps file to the default file name under log_dir" do
          expect(SemanticLogger).to receive(:add_appender).with(file_name: "/tmp/logs/pact_broker.log")
          build({ stream: :file })
        end

        it "honours an explicit file_name" do
          expect(SemanticLogger).to receive(:add_appender).with(file_name: "/var/log/custom.log")
          build({ stream: :file, file_name: "/var/log/custom.log" })
        end
      end

      describe "format resolution" do
        it "passes a named format through as a symbol" do
          expect(SemanticLogger).to receive(:add_appender).with(io: $stdout, formatter: :json)
          build({ stream: :stdout, format: :json })
        end

        it "omits the formatter when no format is given, preserving the gem default" do
          expect(SemanticLogger).to receive(:add_appender).with(io: $stdout)
          build({ stream: :stdout })
        end

        context "when format is auto" do
          it "resolves to color on a tty" do
            allow($stdout).to receive(:tty?).and_return(true)
            expect(SemanticLogger).to receive(:add_appender).with(io: $stdout, formatter: :color)
            build({ stream: :stdout, format: :auto })
          end

          it "resolves to json when not a tty" do
            allow($stdout).to receive(:tty?).and_return(false)
            expect(SemanticLogger).to receive(:add_appender).with(io: $stdout, formatter: :json)
            build({ stream: :stdout, format: :auto })
          end

          it "resolves to json for a file, which is never a tty" do
            expect(SemanticLogger).to receive(:add_appender).with(file_name: "/tmp/logs/pact_broker.log", formatter: :json)
            build({ stream: :file, format: :auto })
          end
        end
      end

      describe "resolving format: :short against the real formatter factory" do
        it "stands on its own, without pact_broker/logging having been loaded" do
          require "open3"

          script = <<~RUBY
            require "pact_broker/logging/appender_factory"
            puts SemanticLogger::Formatters.factory(:short).class
          RUBY
          out, status = Open3.capture2e("bundle", "exec", "ruby", "-Ilib", "-e", script)

          expect(status).to be_success, out
          expect(out.strip).to eq "SemanticLogger::Formatters::Short"
        end
      end

      describe "sugar-key precedence over explicit pass-through options" do
        it "lets stream: win over an explicit io:" do
          expect(SemanticLogger).to receive(:add_appender).with(io: $stdout)
          build({ stream: :stdout, io: $stderr })
        end

        it "lets format: win over an explicit formatter:" do
          expect(SemanticLogger).to receive(:add_appender).with(io: $stdout, formatter: :json)
          build({ stream: :stdout, format: :json, formatter: :logfmt })
        end
      end

      describe "pass-through of unknown options" do
        it "forwards options this class knows nothing about" do
          expect(SemanticLogger).to receive(:add_appender).with(
            appender: :loki, url: "http://loki:3100", level: :warn
          )
          build({ appender: :loki, url: "http://loki:3100", level: :warn })
        end

        it "does not forward the sugar keys" do
          expect(SemanticLogger).to receive(:add_appender).with(io: $stdout, formatter: :json)
          build({ stream: :stdout, format: :json, enabled: true })
        end
      end

      describe "enabled" do
        it "returns nil and adds nothing when false" do
          expect(SemanticLogger).to_not receive(:add_appender)
          expect(build({ stream: :stdout, enabled: false })).to be_nil
        end

        it "adds the appender when true" do
          expect(SemanticLogger).to receive(:add_appender)
          build({ stream: :stdout, enabled: true })
        end

        it "adds the appender when unspecified" do
          expect(SemanticLogger).to receive(:add_appender)
          build({ stream: :stdout })
        end
      end

      describe "when the appender's gem is not available" do
        before do
          allow(SemanticLogger).to receive(:add_appender).and_raise(
            LoadError.new('Gem opentelemetry-logs-sdk is required for logging to Open Telemetry.')
          )
        end

        it "skips silently when enabled is auto" do
          expect(build({ appender: :open_telemetry, enabled: :auto })).to be_nil
        end

        it "raises a ConfigurationError naming the entry index when enabled is true" do
          expect {
            build({ appender: :open_telemetry, enabled: true }, index: 2)
          }.to raise_error(PactBroker::ConfigurationError, /log_appenders entry 2.*opentelemetry-logs-sdk/m)
        end

        it "raises a ConfigurationError when enabled is unspecified" do
          expect {
            build({ appender: :open_telemetry }, index: 1)
          }.to raise_error(PactBroker::ConfigurationError, /log_appenders entry 1/)
        end
      end

      describe "when add_appender rejects the options" do
        it "wraps the error, naming the entry index" do
          allow(SemanticLogger).to receive(:add_appender).and_raise(ArgumentError.new("unknown keyword: :formatt"))

          expect {
            build({ stream: :stdout, formatt: :json }, index: 3)
          }.to raise_error(PactBroker::ConfigurationError, /log_appenders entry 3.*unknown keyword/m)
        end
      end
    end
  end
end
