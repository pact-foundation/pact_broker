require "pact_broker/logging/appender_entries"
require "pact_broker/config/runtime_configuration"

module PactBroker
  module Logging
    describe AppenderEntries do
      let(:runtime_configuration) { PactBroker::Config::RuntimeConfiguration.new }

      subject { AppenderEntries.call(runtime_configuration) }

      context "when nothing is configured" do
        it "reproduces the historical default: a file appender plus opportunistic OTel" do
          expect(subject.entries).to eq [
            { stream: :file },
            AppenderEntries::DEFAULT_OTEL_ENTRY
          ]
        end

        it "does not warn, because the operator has not asked for anything deprecated" do
          expect(subject.warnings).to be_empty
        end
      end

      context "when the deprecated settings are used on their own" do
        before do
          allow(runtime_configuration).to receive(:log_setting_explicitly_set?).and_return(false)
          allow(runtime_configuration).to receive(:log_setting_explicitly_set?).with(:log_stream).and_return(true)
          allow(runtime_configuration).to receive(:log_setting_explicitly_set?).with(:log_format).and_return(true)
          runtime_configuration.log_stream = "stdout"
          runtime_configuration.log_format = "json"
        end

        it "still honours them" do
          expect(subject.entries).to eq [
            { stream: :stdout, format: :json },
            AppenderEntries::DEFAULT_OTEL_ENTRY
          ]
        end

        it "warns that they are deprecated, naming the replacement" do
          expect(subject.warnings.join("\n")).to match(/log_stream.*deprecated.*log_appenders/m)
        end

        it "shows the equivalent log_appenders value so the fix is copy-pasteable" do
          expect(subject.warnings.join("\n")).to include("stream: stdout")
          expect(subject.warnings.join("\n")).to include("format: json")
        end

        it "warns about a future major version removal" do
          expect(subject.warnings.join("\n")).to match(/removed in a future major version/)
        end

        it "does not warn about log_dir or log_level, which are not deprecated" do
          expect(subject.warnings.join("\n")).to_not include("log_dir")
          expect(subject.warnings.join("\n")).to_not include("log_level")
        end
      end

      context "when only log_stream is explicitly set" do
        before do
          allow(runtime_configuration).to receive(:log_setting_explicitly_set?).and_return(false)
          allow(runtime_configuration).to receive(:log_setting_explicitly_set?).with(:log_stream).and_return(true)
          runtime_configuration.log_stream = "stdout"
        end

        it "only mentions log_stream" do
          expect(subject.warnings.join("\n")).to include("log_stream")
          expect(subject.warnings.join("\n")).to_not include("log_format")
        end
      end

      context "when log_appenders is set" do
        before do
          runtime_configuration.log_appenders = [{ stream: :stderr, format: :logfmt }]
        end

        it "uses it verbatim, and does not add an OTel entry the operator did not ask for" do
          expect(subject.entries).to eq [{ stream: :stderr, format: :logfmt }]
        end

        it "does not warn when the deprecated settings were left alone" do
          allow(runtime_configuration).to receive(:log_setting_explicitly_set?).and_return(false)

          expect(subject.warnings).to be_empty
        end

        context "and the deprecated settings are also set" do
          before do
            allow(runtime_configuration).to receive(:log_setting_explicitly_set?).and_return(false)
            allow(runtime_configuration).to receive(:log_setting_explicitly_set?).with(:log_stream).and_return(true)
            runtime_configuration.log_stream = "stdout"
          end

          it "still uses log_appenders" do
            expect(subject.entries).to eq [{ stream: :stderr, format: :logfmt }]
          end

          it "warns that the deprecated setting is being ignored, which is the more urgent case" do
            expect(subject.warnings.join("\n")).to match(/log_stream.*ignored.*log_appenders/m)
          end
        end
      end

      context "when log_appenders is explicitly empty" do
        before do
          runtime_configuration.log_appenders = []
        end

        it "produces no entries, meaning no logging" do
          expect(subject.entries).to eq []
        end
      end
    end
  end
end
