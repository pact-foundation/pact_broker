require 'pact_broker/api/decorators/environment_decorator'
require 'pact_broker/environments/repository'

module PactBroker
  module Api
    module Decorators
      describe EnvironmentDecorator do
        let(:environment) do
          TestDataBuilder.new
            .create_consumer("Consumer")
            .create_version("1.2.3")
            .create_environment("prod")
            .and_return(:environment)
        end

        let(:options) { { user_options: { base_url: 'http://example.org' } } }

        subject { JSON.parse EnvironmentDecorator.new(environment).to_json(options), symbolize_names: true }

        it "includes the environment name" do
          expect(subject[:name]).to eq "prod"
        end

        it "includes a link to itself" do
          expect(subject[:_links][:self][:href]).to eq "http://example.org/pacticipants/Consumer/versions/1.2.3/environments/prod"
        end

        it "includes the environment name" do
          expect(subject[:_links][:self][:name]).to eq "prod"
        end

        it "includes a link to the version" do
          expect(subject[:_links][:version][:href]).to eq "http://example.org/pacticipants/Consumer/versions/1.2.3"
        end

        it "includes the version number" do
          expect(subject[:_links][:version][:name]).to eq "1.2.3"
        end

        it "includes a link to the pacticipant" do
          expect(subject[:_links][:pacticipant][:href]).to eq "http://example.org/pacticipants/Consumer"
        end

        it "includes the pacticipant name" do
          expect(subject[:_links][:pacticipant][:name]).to eq "Consumer"
        end
      end
    end
  end
end
