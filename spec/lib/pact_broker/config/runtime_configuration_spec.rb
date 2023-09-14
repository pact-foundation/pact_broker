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
    end
  end
end
