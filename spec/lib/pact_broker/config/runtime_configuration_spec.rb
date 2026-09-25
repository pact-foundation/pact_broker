require "pact_broker/config/runtime_configuration"
require "anyway/testing/helpers"

module PactBroker
  module Config
    describe RuntimeConfiguration do
      include Anyway::Testing::Helpers

      describe "base_url" do
        it "does not expose base_url for delegation" do
          expect(RuntimeConfiguration.getter_and_setter_method_names).to_not include :base_url
        end

        it "does not support the method base_url as base_urls should be used instead" do
          expect { RuntimeConfiguration.new.base_url }.to raise_error NotImplementedError
        end
      end

      context "with a base_url and base_urls as strings" do
        subject do
          runtime_configuration = RuntimeConfiguration.new
          runtime_configuration.base_url = "foo blah"
          runtime_configuration.base_urls = "bar wiffle"
          runtime_configuration
        end

        its(:base_urls) { is_expected.to eq %w[bar wiffle foo blah] }
      end

      context "with a base_url and base_urls as the same strings" do
        subject do
          runtime_configuration = RuntimeConfiguration.new
          runtime_configuration.base_url = "foo blah"
          runtime_configuration.base_urls = "foo meep"
          runtime_configuration
        end

        its(:base_urls) { is_expected.to eq %w[foo meep blah] }
      end

      context "with just base_url as a string" do
        subject do
          runtime_configuration = RuntimeConfiguration.new
          runtime_configuration.base_url = "foo blah"
          runtime_configuration
        end

        its(:base_urls) { is_expected.to eq %w[foo blah] }
      end

      context "with just base_urls as a string" do
        subject do
          runtime_configuration = RuntimeConfiguration.new
          runtime_configuration.base_url = nil
          runtime_configuration.base_urls = "bar wiffle"
          runtime_configuration
        end

        its(:base_urls) { is_expected.to eq %w[bar wiffle] }
      end

      context "with base_url and base_urls as arrays" do
        subject do
          runtime_configuration = RuntimeConfiguration.new
          runtime_configuration.base_url = %w[foo blah]
          runtime_configuration.base_urls = %w[bar wiffle]
          runtime_configuration
        end

        its(:base_urls) { is_expected.to eq %w[bar wiffle foo blah] }
      end

      describe "webhook_certificates" do
        context "when setting using environment variables with indexes eg PACT_BROKER_WEBHOOK_CERTIFICATES__0__DESCRIPTION" do
          it "parses the environment variables to a list of hashes" do
            with_env(
                "PACT_BROKER_WEBHOOK_CERTIFICATES__0__DESCRIPTION" => "cert1",
                "PACT_BROKER_WEBHOOK_CERTIFICATES__0__CONTENT" => "abc",
                "PACT_BROKER_WEBHOOK_CERTIFICATES__1__DESCRIPTION" => "cert2",
                "PACT_BROKER_WEBHOOK_CERTIFICATES__1__CONTENT" => "abc2",
              ) do
              expect(RuntimeConfiguration.new.webhook_certificates).to eq [{ description: "cert1", content: "abc" }, { description: "cert2", content: "abc2" }]
            end
          end

          context "when the environment variables are not the right structure" do
            it "raises an error" do
              with_env(
                  "PACT_BROKER_WEBHOOK_CERTIFICATES__a__DESCRIPTION" => "cert1",
                  "PACT_BROKER_WEBHOOK_CERTIFICATES__a__CONTENT" => "abc",
                  "PACT_BROKER_WEBHOOK_CERTIFICATES__b__DESCRIPTION" => "cert2",
                  "PACT_BROKER_WEBHOOK_CERTIFICATES__b__CONTENT" => "abc2",
                ) do
                expect { RuntimeConfiguration.new }.to raise_error PactBroker::ConfigurationError, /Could not coerce*/
              end
            end
          end
        end

        context "when loading from YAML" do
          it "coerces the keys to symbols" do
            with_env("PACT_BROKER_CONF" => PactBroker.project_root.join("spec/support/config_webhook_certificates.yml").to_s) do
              expect(RuntimeConfiguration.new.webhook_certificates.first.keys.collect(&:class).uniq).to eq [Symbol]
            end
          end
        end

        context "when loading from YAML with the wrong structure" do
          it "raises an error" do
            with_env("PACT_BROKER_CONF" => PactBroker.project_root.join("spec/support/config_webhook_certificates_wrong_structure.yml").to_s) do
              expect { RuntimeConfiguration.new }.to raise_error PactBroker::ConfigurationError, "Webhook certificates cannot be set using a String"
            end
          end
        end
      end

      describe "features" do
        context "with the PACT_BROKER_FEATURES env var with a space delimited list of enabled features" do
          it "parses the string to a hash" do
            with_env("PACT_BROKER_FEATURES" => "feat1 feat2") do
              expect(RuntimeConfiguration.new.features).to eq feat1: true, feat2: true
            end
          end
        end

        context "with the PACT_BROKER_FEATURES env var with an empty string" do
          it "parses the string to a hash" do
            with_env("PACT_BROKER_FEATURES" => "") do
              expect(RuntimeConfiguration.new.features).to eq({})
            end
          end
        end

        context "with a different env var for each feature" do
          it "merges the env vars into a hash" do
            with_env("PACT_BROKER_FEATURES__FEAT1" => "true", "PACT_BROKER_FEATURES__FEAT2" => "false") do
              expect(RuntimeConfiguration.new.features).to eq feat1: true, feat2: false
            end
          end
        end

        context "with the list env var defined first and the individual env vars defined last" do
          it "uses the individual env vars" do
            with_env("PACT_BROKER_FEATURES" => "feat1 feat2 feat3", "PACT_BROKER_FEATURES__FEAT4" => "true", "PACT_BROKER_FEATURES__FEAT5" => "false") do
              expect(RuntimeConfiguration.new.features).to eq feat4: true, feat5: false
            end
          end
        end

        context "with the individual env vars defined first and the list env var defined last" do
          it "uses the list env var" do
            with_env("PACT_BROKER_FEATURES__FEAT4" => "true", "PACT_BROKER_FEATURES__FEAT5" => "false", "PACT_BROKER_FEATURES" => "feat1 feat2 feat3") do
              expect(RuntimeConfiguration.new.features).to eq feat1: true, feat2: true, feat3: true
            end
          end
        end

        context "with no feature env vars" do
          it "returns an empty hash" do
            expect(RuntimeConfiguration.new.features).to eq({})
          end
        end
      end

      describe "log_appenders" do
        it "is nil by default, so that Logging::AppenderEntries can tell it was not configured" do
          expect(RuntimeConfiguration.new.log_appenders).to be_nil
        end

        context "when set from YAML style data" do
          it "symbolizes the keys and coerces the known values" do
            config = RuntimeConfiguration.new
            config.log_appenders = [
              { "stream" => "stdout", "format" => "json" },
              { "appender" => "open_telemetry", "enabled" => "auto" }
            ]

            expect(config.log_appenders).to eq [
              { stream: :stdout, format: :json },
              { appender: :open_telemetry, enabled: :auto }
            ]
          end

          it "leaves unknown pass-through options as they are, but symbolizes their keys" do
            config = RuntimeConfiguration.new
            config.log_appenders = [{ "appender" => "loki", "url" => "http://loki:3100" }]

            expect(config.log_appenders).to eq [{ appender: :loki, url: "http://loki:3100" }]
          end

          it "passes through an appender instance rather than trying to coerce it to a symbol" do
            appender_instance = Object.new
            config = RuntimeConfiguration.new
            config.log_appenders = [{ "appender" => appender_instance, "enabled" => "auto" }]

            expect(config.log_appenders).to eq [{ appender: appender_instance, enabled: :auto }]
          end

          it "coerces enabled true and false" do
            config = RuntimeConfiguration.new
            config.log_appenders = [{ "stream" => "stdout", "enabled" => "false" }]
            expect(config.log_appenders.first[:enabled]).to eq false

            config.log_appenders = [{ "stream" => "stdout", "enabled" => "true" }]
            expect(config.log_appenders.first[:enabled]).to eq true
          end

          it "accepts an explicitly empty list, meaning no appenders" do
            config = RuntimeConfiguration.new
            config.log_appenders = []

            expect(config.log_appenders).to eq []
            expect(config.log_appenders_explicitly_set?).to be true
          end
        end

        context "when set using indexed environment variables" do
          it "converts the numerically indexed hash into an array" do
            with_env(
              "PACT_BROKER_LOG_APPENDERS__0__STREAM" => "stdout",
              "PACT_BROKER_LOG_APPENDERS__0__FORMAT" => "json",
              "PACT_BROKER_LOG_APPENDERS__1__APPENDER" => "open_telemetry",
              "PACT_BROKER_LOG_APPENDERS__1__ENABLED" => "auto"
            ) do
              expect(RuntimeConfiguration.new.log_appenders).to eq [
                { stream: :stdout, format: :json },
                { appender: :open_telemetry, enabled: :auto }
              ]
            end
          end

          it "raises a ConfigurationError when the keys are not numeric" do
            with_env(
              "PACT_BROKER_LOG_APPENDERS__a__STREAM" => "stdout"
            ) do
              expect { RuntimeConfiguration.new.log_appenders }.to raise_error(PactBroker::ConfigurationError, /log_appenders/)
            end
          end
        end

        describe "validation" do
          def config_with(appenders)
            config = RuntimeConfiguration.new
            config.log_appenders = appenders
            config
          end

          it "rejects an entry that specifies neither stream nor appender" do
            expect { config_with([{ format: :json }]) }
              .to raise_error(PactBroker::ConfigurationError, /entry 0.*must specify one of/m)
          end

          it "rejects an entry that specifies both stream and appender" do
            expect { config_with([{ stream: :stdout, appender: :loki }]) }
              .to raise_error(PactBroker::ConfigurationError, /entry 0.*both/m)
          end

          it "rejects an unknown stream, listing the valid values" do
            expect { config_with([{ stream: :socket }]) }
              .to raise_error(PactBroker::ConfigurationError, /entry 0.*stdout, stderr, file/m)
          end

          it "rejects an unknown format, listing the valid values" do
            expect { config_with([{ stream: :stdout, format: :jsn }]) }
              .to raise_error(PactBroker::ConfigurationError, /entry 0.*default, color, json/m)
          end

          it "rejects file_name on a stream that is not file" do
            expect { config_with([{ stream: :stdout, file_name: "/tmp/x.log" }]) }
              .to raise_error(PactBroker::ConfigurationError, /entry 0.*file_name/m)
          end

          it "rejects an invalid enabled value" do
            expect { config_with([{ stream: :stdout, enabled: :maybe }]) }
              .to raise_error(PactBroker::ConfigurationError, /entry 0.*enabled/m)
          end

          it "names the index of the offending entry" do
            expect { config_with([{ stream: :stdout }, { stream: :nope }]) }
              .to raise_error(PactBroker::ConfigurationError, /entry 1/)
          end

          it "accepts a valid list" do
            expect {
              config_with([{ stream: :stdout, format: :auto, level: :warn }, { appender: :open_telemetry, enabled: :auto }])
            }.to_not raise_error
          end
        end
      end

      describe "log_application and log_environment" do
        it "defaults log_application to pact-broker" do
          expect(RuntimeConfiguration.new.log_application).to eq "pact-broker"
        end

        it "defaults log_application to OTEL_SERVICE_NAME when it is set" do
          with_env("OTEL_SERVICE_NAME" => "my-service") do
            expect(RuntimeConfiguration.new.log_application).to eq "my-service"
          end
        end

        it "defaults log_environment to nil" do
          expect(RuntimeConfiguration.new.log_environment).to be_nil
        end
      end

      describe "#log_setting_explicitly_set?" do
        it "is false when the value came from the defaults" do
          expect(RuntimeConfiguration.new.log_setting_explicitly_set?(:log_stream)).to be false
        end

        it "is true when the value came from an environment variable" do
          with_env("PACT_BROKER_LOG_STREAM" => "stdout") do
            expect(RuntimeConfiguration.new.log_setting_explicitly_set?(:log_stream)).to be true
          end
        end
      end

      describe "removed settings" do
        it "no longer has log_otel_enabled" do
          expect(RuntimeConfiguration.new).to_not respond_to(:log_otel_enabled)
        end

        it "no longer has custom_log_formatters=" do
          expect(RuntimeConfiguration.new).to_not respond_to(:custom_log_formatters=)
        end
      end
    end
  end
end
