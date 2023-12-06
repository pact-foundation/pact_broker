require "pact_broker/api/decorators/versions_decorator"
require "pact_broker/domain/version"

module PactBroker
  module Api
    module Decorators
      describe VersionsDecorator do
        before do
          allow_any_instance_of(VersionsDecorator::VersionInCollectionDecorator).to receive(:version_url).and_return("version_url")
        end

        let(:options) { { request_url: "http://versions?foo=bar", base_url: "http://example.org", pacticipant_name: "Consumer", resource_url: "http://versions" } }
        let(:versions) { [] }
        let(:decorator) { VersionsDecorator.new(versions) }
        let(:json) { decorator.to_json(user_options: options) }

        subject { JSON.parse(json, symbolize_names: true)  }

        its([:_links, :self, :href]) { is_expected.to eq "http://versions?foo=bar" }

        context "with no versions" do
          it "doesn't blow up" do
            subject
          end
        end

        context "with versions" do
          let!(:version) do
            td
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

          it "has the version href with the version number" do
            expect(subject[:_embedded][:versions].first[:_links][:self][:href]).to eq "version_url"
          end
        end
      end
    end
  end
end
