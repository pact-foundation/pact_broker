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
        context "when setting using environment variables with indexes eg PACT_BROKER_WEBHOOK_CERTIFICATES__0__LABEL" do
          subject do
            runtime_configuration = RuntimeConfiguration.new
            runtime_configuration.webhook_certificates = { "0" => { "description" => "cert1", "content" => "abc" }, "1" => { "description" => "cert1", "content" => "abc" } }
            runtime_configuration
          end

          its(:webhook_certificates) { is_expected.to eq [{ description: "cert1", content: "abc" }, { description: "cert1", content: "abc" }] }
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
