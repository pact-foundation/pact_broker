require "pact_broker/config/runtime_configuration"

module PactBroker
  module Config
    describe RuntimeConfiguration do
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
    end
  end
end
