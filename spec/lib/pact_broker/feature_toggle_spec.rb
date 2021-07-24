require "pact_broker/feature_toggle"
require "anyway/testing/helpers"

module PactBroker
  describe FeatureToggle do
    describe "enabled?" do
      include Anyway::Testing::Helpers

      let(:ignore_env) { false }

      subject { FeatureToggle.enabled?(:foo, ignore_env) }

      context "when RACK_ENV is not production" do
        around do | example |
          with_env("RACK_ENV" => "development", &example)
        end

        context "when PACT_BROKER_FEATURES includes the given string" do
          around do | example |
            with_env("PACT_BROKER_FEATURES" => "foo bar", &example)
          end

          it { is_expected.to be true }
        end

        context "when PACT_BROKER_FEATURES does not include the given string" do
          around do | example |
            with_env("PACT_BROKER_FEATURES" => "", &example)
          end

          it { is_expected.to be true }

          context "when ignore env is set" do
            let(:ignore_env) { true }

            it { is_expected.to be false }
          end
        end
      end

      context "when RACK_ENV is production" do
        around do | example |
          with_env("RACK_ENV" => "production", &example)
        end

        context "when PACT_BROKER_FEATURES includes the given string" do
          around do | example |
            with_env("PACT_BROKER_FEATURES" => "foo bar", &example)
          end

          it { is_expected.to be true }
        end

        context "when PACT_BROKER_FEATURES includes the given string inside another word" do
          around do | example |
            with_env("PACT_BROKER_FEATURES" => "foowiffle bar", &example)
          end

          it { is_expected.to be false }
        end

        context "when PACT_BROKER_FEATURES includes the given string but the case doesn't match" do
          around do | example |
            with_env("PACT_BROKER_FEATURES" => "FOO bar", &example)
          end

          it { is_expected.to be true }
        end

        context "when PACT_BROKER_FEATURES does not include the given string" do
          around do | example |
            with_env("PACT_BROKER_FEATURES" => nil, &example)
          end

          it { is_expected.to be false }
        end
      end
    end
  end
end
