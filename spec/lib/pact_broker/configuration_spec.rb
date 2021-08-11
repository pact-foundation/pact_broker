require "spec_helper"
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

    describe "with_runtime_configuration_overrides" do
      before do
        allow(PactBroker.configuration).to receive(:logger).and_return(logger)
      end
      let(:logger) { double("logger", debug?: true, debug: nil, warn: nil) }

      it "overrides the specified runtime configuration attributes within the block" do
        attribute_in_block = nil
        PactBroker.with_runtime_configuration_overrides(webhook_http_code_success: [400]) do
          attribute_in_block = PactBroker.configuration.webhook_http_code_success
        end
        expect(attribute_in_block).to eq [400]
        expect(PactBroker.configuration.webhook_http_code_success).to_not eq [400]
      end

      it "logs the overrides at debug level" do
        expect(logger).to receive(:debug).with("Overridding runtime configuration attribute 'webhook_http_code_success' with value [400]")
        PactBroker.with_runtime_configuration_overrides(webhook_http_code_success: [400]) do
          "foo"
        end
      end

      it "does not override the other runtime configuration attributes within the block" do
        attribute_in_block = nil
        PactBroker.with_runtime_configuration_overrides(webhook_http_code_success: [400]) do
          attribute_in_block = PactBroker.configuration.webhook_scheme_whitelist
        end
        expect(PactBroker.configuration.webhook_scheme_whitelist).to eq attribute_in_block
      end

      it "returns the results of the block" do
        return_value = PactBroker.with_runtime_configuration_overrides(webhook_http_code_success: [400]) do
          "foo"
        end
        expect(return_value).to eq "foo"
      end

      context "when the specified runtime attribute does not exist" do
        it "logs an error" do
          expect(logger).to receive(:warn).with(/Cannot override runtime configuration attribute 'no_existy'/)
          PactBroker.with_runtime_configuration_overrides(no_existy: true) do
            "foo"
          end
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
