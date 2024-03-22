require "pact_broker/configuration"
require "pact_broker/api/renderers/html_pact_renderer"
require "pact_broker/config/setting"

module PactBroker
  describe Configuration do
    describe "show_backtrace_in_error_response?" do
      before do
        allow(ENV).to receive(:[]).and_call_original
      end

      context "when RACK_ENV is not set" do
        before do
          allow(ENV).to receive(:[]).with("RACK_ENV").and_return(nil)
        end

        its(:show_backtrace_in_error_response?) { is_expected.to be false }
      end

      context "when RACK_ENV is not production" do
        before do
          allow(ENV).to receive(:[]).with("RACK_ENV").and_return("development")
        end

        its(:show_backtrace_in_error_response?) { is_expected.to be true }
      end

      context "when RACK_ENV is production" do
        before do
          allow(ENV).to receive(:[]).with("RACK_ENV").and_return("production")
        end

        its(:show_backtrace_in_error_response?) { is_expected.to be false }
      end
    end

    describe "override_runtime_configuration!" do
      let(:logger) { double("logger", debug?: true, debug: nil, warn: nil) }

      let(:config) { PactBroker.configuration.dup }

      it "overrides the specified runtime configuration attributes" do
        config.override_runtime_configuration!(disable_ssl_verification: "true")
        expect(config.disable_ssl_verification).to eq true
        expect(PactBroker.configuration.disable_ssl_verification).to eq false
      end

      it "logs the overrides at debug level" do
        allow(config).to receive(:logger).and_return(logger)
        expect(logger).to receive(:debug).with("Overriding runtime configuration", hash_including(overrides: { disable_ssl_verification: true }))
        config.override_runtime_configuration!(disable_ssl_verification: "true")
      end

      it "does not override the other runtime configuration attributes" do
        expect { config.override_runtime_configuration!(disable_ssl_verification: "true") }.to_not change { config.webhook_scheme_whitelist }
      end

      context "when the specified runtime attribute does not exist" do
        it "logs that it has ignored those attributes" do
          allow(config).to receive(:logger).and_return(logger)
          expect(logger).to receive(:debug).with("Overriding runtime configuration", hash_including(ignoring: { no_existy: true }))
          config.override_runtime_configuration!(no_existy: "true")
        end
      end

      context "when overriding config items that are hashes" do
        it "merges them" do
          config.features = { feat_a: true, feat_b: false }
          config.override_runtime_configuration!(features: { feat_a: false, feat_c: true })
          expect(config.features).to eq feat_a: false, feat_b: false, feat_c: true
        end
      end

      context "when the configuration is frozen" do
        it "raises an error" do
          config.freeze
          expect { config.override_runtime_configuration!(disable_ssl_verification: "true") }.to raise_error FrozenError
        end
      end
    end

    describe "default configuration" do
      describe ".html_pact_renderer" do

        let(:pact) { double("pact") }
        let(:options) { double("options") }

        it "calls the inbuilt HtmlPactRenderer" do
          expect(PactBroker::Api::Renderers::HtmlPactRenderer).to receive(:call).with(pact, options)
          PactBroker.configuration.html_pact_renderer.call pact, options
        end
      end

      describe "webhook_http_method_whitelist" do
        it "allows setting the whitelist by a string" do
          PactBroker.configuration.webhook_http_method_whitelist = "foo"
          expect(PactBroker.configuration.webhook_http_method_whitelist).to be_a Config::SpaceDelimitedStringList
        end

        it "allows setting the whitelist by an array" do
          PactBroker.configuration.webhook_http_method_whitelist = ["foo", "/.*/"]
          expect(PactBroker.configuration.webhook_http_method_whitelist).to eq ["foo", /.*/]
        end
      end

      describe "webhook_http_code_success" do
        it "allows setting the 'webhook_http_code_success' by a space-delimited string" do
          PactBroker.configuration.webhook_http_code_success = "200 201 202"
          expect(PactBroker.configuration.webhook_http_code_success).to be_a Config::SpaceDelimitedIntegerList
        end

        it "allows setting the 'webhook_http_code_success' by an array" do
          PactBroker.configuration.webhook_http_code_success = [200, 201, 202]
          expect(PactBroker.configuration.webhook_http_code_success).to eq [200, 201, 202]
        end
      end

      describe "webhook_scheme_whitelist" do
        it "allows setting the whitelist by a string" do
          PactBroker.configuration.webhook_scheme_whitelist = "foo"
          expect(PactBroker.configuration.webhook_scheme_whitelist).to be_a Config::SpaceDelimitedStringList
        end
      end

      describe "webhook_host_whitelist" do
        it "allows setting the whitelist by a string" do
          PactBroker.configuration.webhook_host_whitelist = "foo"
          expect(PactBroker.configuration.webhook_host_whitelist).to be_a Config::SpaceDelimitedStringList
        end
      end

      describe "load_from_database!" do
        let(:configuration) { PactBroker::Configuration.new }

        before do
          PactBroker::Config::Setting.create(name: "use_case_sensitive_resource_names", type: "string", value: "foo")
        end

        it "loads the configurations from the database" do
          configuration.load_from_database!
          expect(configuration.use_case_sensitive_resource_names).to eq "foo"
        end
      end

      describe "add_api_error_reporter" do
        let(:configuration) { PactBroker::Configuration.new }
        let(:block) { Proc.new{ | error, options | } }

        it "should add the error notifier " do
          configuration.add_api_error_reporter(&block)
          expect(configuration.api_error_reporters.first).to eq block
        end

        context "with a proc with the wrong number of arguments" do
          let(:block) { Proc.new{ | error | } }

          it "raises an error" do
            expect { configuration.add_api_error_reporter(&block) }.to raise_error PactBroker::ConfigurationError
          end
        end
      end
    end
  end
end
