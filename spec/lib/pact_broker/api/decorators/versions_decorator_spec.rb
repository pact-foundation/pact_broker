require "pact_broker/api/decorators/versions_decorator"
require "pact_broker/domain/version"

module PactBroker
  module Api
    module Decorators
      describe VersionsDecorator do

        let(:options) { { resource_url: "http://versions", base_url: "http://example.org", pacticipant_name: "Consumer", query_string: query_string}}
        let(:query_string) { nil }
        let(:versions) { [] }

        subject { JSON.parse VersionsDecorator.new(versions).to_json(user_options: options), symbolize_names: true }

        context "with no query string" do
          its([:_links, :self, :href]) { is_expected.to eq "http://versions" }
        end

        context "with a query string" do
          let(:query_string) { "foo=bar" }
          its([:_links, :self, :href]) { is_expected.to eq "http://versions?foo=bar" }
        end

        context "with no versions" do
          it "doesn't blow up" do
            subject
          end
        end

        context "with versions" do
          let!(:version) do
            TestDataBuilder.new
              .create_consumer("Consumer")
              .create_consumer_version("1.2.3")
              .create_consumer_version_tag("prod")
              .and_return(:consumer_version)
          end
          let(:versions) { [version] }

          it "displays a list of versions" do
            expect(subject[:_embedded][:versions]).to be_instance_of(Array)
            expect(subject[:_embedded][:versions].size).to eq 1
          end
        end
      end
    end
  end
end
