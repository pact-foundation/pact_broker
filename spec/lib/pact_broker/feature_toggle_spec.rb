require "pact_broker/feature_toggle"

module PactBroker
  describe FeatureToggle do
    describe "enabled?" do
      before do
        allow(ENV).to receive(:[]).and_call_original
      end

      let(:ignore_env) { false }

      subject { FeatureToggle.enabled?(:foo, ignore_env) }

      context "when RACK_ENV is not production" do
        before do
          allow(ENV).to receive(:[]).with("RACK_ENV").and_return("development")
        end

        context "when PACT_BROKER_FEATURES includes the given string" do
          before do
            allow(ENV).to receive(:[]).with("PACT_BROKER_FEATURES").and_return("foo bar")
          end

          it { is_expected.to be true }
        end

        context "when PACT_BROKER_FEATURES does not include the given string" do
          before do
            allow(ENV).to receive(:[]).with("PACT_BROKER_FEATURES").and_return(nil)
          end

          it { is_expected.to be true }

          context "when ignore env is set" do
            let(:ignore_env) { true }

            it { is_expected.to be false }
          end
        end
      end

      context "when RACK_ENV is production" do
        before do
          allow(ENV).to receive(:[]).with("RACK_ENV").and_return("production")
        end

        context "when PACT_BROKER_FEATURES includes the given string" do
          before do
            allow(ENV).to receive(:[]).with("PACT_BROKER_FEATURES").and_return("foo bar")
          end

          it { is_expected.to be true }
        end

        context "when PACT_BROKER_FEATURES includes the given string inside another word" do
          before do
            allow(ENV).to receive(:[]).with("PACT_BROKER_FEATURES").and_return("foowiffle bar")
          end

          it { is_expected.to be false }
        end

        context "when PACT_BROKER_FEATURES includes the given string but the case doesn't match" do
          before do
            allow(ENV).to receive(:[]).with("PACT_BROKER_FEATURES").and_return("FOO bar")
          end

          it { is_expected.to be true }
        end

        context "when PACT_BROKER_FEATURES does not include the given string" do
          before do
            allow(ENV).to receive(:[]).with("PACT_BROKER_FEATURES").and_return(nil)
          end

          it { is_expected.to be false }
        end
      end
    end
  end
end
