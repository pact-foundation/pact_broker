require 'pact_broker/api/decorators/embedded_environment_decorator'
require 'pact_broker/environments/repository'
require 'support/test_data_builder'

module PactBroker
  module Api
    module Decorators
      describe EmbeddedEnvironmentDecorator do
        let(:environment) do
          TestDataBuilder.new
            .create_consumer("Consumer")
            .create_version("1.2.3")
            .create_environment("prod")
            .and_return(:environment)
        end

        let(:options) { { user_options: { base_url: 'http://example.org' } } }
        let(:json) { EmbeddedEnvironmentDecorator.new(environment).to_json(options) }

        subject { JSON.parse json, symbolize_names: true }

        it "includes the environment name" do
          expect(subject[:name]).to eq "prod"
        end

        it "includes a link to itself" do
          expect(subject[:_links][:self][:href]).to eq "http://example.org/pacticipants/Consumer/versions/1.2.3/environments/prod"
        end

        it "includes the environment name" do
          expect(subject[:_links][:self][:name]).to eq "prod"
        end
      end
    end
  end
end
