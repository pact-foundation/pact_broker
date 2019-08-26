require 'spec_helper'
require 'pact_broker/api/decorators/pact_decorator'

module PactBroker
  module Api
    module Decorators
      describe PactDecorator do
        before do
          allow(decorator).to receive(:templated_diff_url).and_return('templated-diff-url')
          allow(decorator).to receive(:verification_publication_url).and_return('verification-publication-url')
        end
        let(:content_hash) {
          {
            'consumer' => {'name' => 'Consumer'},
            'provider' => {'name' => 'Provider'},
            'interactions' => [],
            'metadata' => {}
          }
        }

        let(:base_url) { 'http://example.org' }
        let(:created_at) { Time.new(2014, 3, 4) }
        let(:pact) { double('pact',
          content_hash: content_hash,
          created_at: created_at,
          consumer: consumer,
          provider: provider,
          consumer_version: consumer_version,
          consumer_version_number: '1234',
          pact_version_sha: '9999',
          revision_number: 2,
          name: 'A Pact'
        )}
        let(:consumer) { instance_double(PactBroker::Domain::Pacticipant, name: 'A Consumer')}
        let(:provider) { instance_double(PactBroker::Domain::Pacticipant, name: 'A Provider')}
        let(:consumer_version) { instance_double(PactBroker::Domain::Version, number: '1234', pacticipant: consumer)}
        let(:metadata) { "abcd" }
        let(:decorator) { PactDecorator.new(pact) }
        let(:json) { decorator.to_json(user_options: { base_url: base_url, metadata: metadata }) }
        subject { JSON.parse(json, symbolize_names: true) }

        describe "#to_json" do

          it "creates the verification link" do
            expect(decorator).to receive(:verification_publication_url).with(pact, base_url, metadata)
            subject
          end

          it "includes the json_content" do
            expect(subject[:consumer]).to eq name: 'Consumer'
          end

          it "includes the createdAt date" do
            expect(subject[:createdAt]).to eq FormatDateTime.call(created_at)
          end

          it "includes a link to itself" do
            expect(subject[:_links][:self]).to eq href: 'http://example.org/pacts/provider/A%20Provider/consumer/A%20Consumer/version/1234', name: 'A Pact', title: 'Pact'
          end

          it "includes a link to the diff with the previous distinct version" do
            expect(subject[:_links][:'pb:diff-previous-distinct']).to eq({href: 'http://example.org/pacts/provider/A%20Provider/consumer/A%20Consumer/version/1234/diff/previous-distinct',
              title: 'Diff with previous distinct version of this pact'})
          end

          it "includes a link to the previous distinct pact version" do
            expect(subject[:_links][:'pb:previous-distinct']).to eq({href: 'http://example.org/pacts/provider/A%20Provider/consumer/A%20Consumer/version/1234/previous-distinct',
              title: 'Previous distinct version of this pact'})
          end

          it "includes a link to tag this version" do
            expect(subject[:_links][:'pb:tag-version'][:href]).to eq "http://example.org/pacticipants/A%20Consumer/versions/1234/tags/{tag}"
          end

          it "includes a link to the consumer" do
            expect(subject[:_links][:'pb:consumer']).to eq name: 'A Consumer', title: 'Consumer', href: "http://example.org/pacticipants/A%20Consumer"
          end

          it "includes a link to the provider" do
            expect(subject[:_links][:'pb:provider']).to eq name: 'A Provider', title: 'Provider', href: "http://example.org/pacticipants/A%20Provider"
          end

          it "includes a link to the webhooks for this pact" do
            expect(subject[:_links][:'pb:pact-webhooks'][:href]).to eq "http://example.org/webhooks/provider/A%20Provider/consumer/A%20Consumer"
          end

          it "includes a link to the latest pact" do
            expect(subject[:_links][:'pb:latest-pact-version'][:title]).to eq "Latest version of this pact"
            expect(subject[:_links][:'pb:latest-pact-version'][:href]).to eq "http://example.org/pacts/provider/A%20Provider/consumer/A%20Consumer/latest"
          end

          it "includes a link to all pact versions" do
            expect(subject[:_links][:'pb:all-pact-versions'][:title]).to eq "All versions of this pact"
            expect(subject[:_links][:'pb:all-pact-versions'][:href]).to eq "http://example.org/pacts/provider/A%20Provider/consumer/A%20Consumer/versions"
          end

          it "includes a link to the pact version" do
            expect(subject[:_links][:'pb:consumer-version'][:title]).to eq "Consumer version"
            expect(subject[:_links][:'pb:consumer-version'][:name]).to eq "1234"
            expect(subject[:_links][:'pb:consumer-version'][:href]).to eq "http://example.org/pacticipants/A%20Consumer/versions/1234"
          end

          it "includes a link to the latest untagged version" do
            expect(subject[:_links][:'pb:latest-untagged-pact-version'][:href]).to eq "http://example.org/pacts/provider/A%20Provider/consumer/A%20Consumer/latest-untagged"
          end

          it "includes a link to the latest tagged version" do
            expect(subject[:_links][:'pb:latest-tagged-pact-version'][:href]).to eq "http://example.org/pacts/provider/A%20Provider/consumer/A%20Consumer/latest/{tag}"
          end

          it "includes a link to publish a verification" do
            expect(subject[:_links][:'pb:publish-verification-results'][:href]).to eq "verification-publication-url"
          end

          it "includes a link to diff this pact version with another pact version" do
            expect(subject[:_links][:'pb:diff'][:href]).to eq 'templated-diff-url'
            expect(subject[:_links][:'pb:diff'][:templated]).to eq true
          end

          it "includes a curie" do
            expect(subject[:_links][:curies]).to eq [{ name: "pb", href: "http://example.org/doc/{rel}?context=pact", templated: true }]
          end

          context "when the json_content is not a Hash" do
            let(:content_hash) { [1] }
            it "returns the plain JSON without any links" do
              expect(subject).to eq content_hash
            end
          end
        end
      end
    end
  end
end
