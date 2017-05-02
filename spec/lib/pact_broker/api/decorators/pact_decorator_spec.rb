require 'spec_helper'
require 'pact_broker/api/decorators/pact_decorator'

module PactBroker

  module Api

    module Decorators

      describe PactDecorator do

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

        subject { JSON.parse PactDecorator.new(pact).to_json(user_options: { base_url: base_url }), symbolize_names: true}

        describe "#to_json" do

          it "includes the json_content" do
            expect(subject[:consumer]).to eq name: 'Consumer'
          end

          it "includes the createdAt date" do
            expect(subject[:createdAt]).to eq created_at.xmlschema
          end

          it "includes a link to itself" do
            expect(subject[:_links][:self]).to eq href: 'http://example.org/pacts/provider/A%20Provider/consumer/A%20Consumer/version/1234', name: 'A Pact', title: 'Pact'
          end

          it "includes a link to the diff with the previous distinct version" do
            expect(subject[:_links][:'pb:diff-previous-distinct']).to eq({href: 'http://example.org/pacts/provider/A%20Provider/consumer/A%20Consumer/version/1234/diff/previous-distinct',
              title: 'Diff',
              name: 'Diff with previous distinct version of this pact'})
          end

          it "includes a link to the previous distinct pact version" do
            expect(subject[:_links][:'pb:previous-distinct']).to eq({href: 'http://example.org/pacts/provider/A%20Provider/consumer/A%20Consumer/version/1234/previous-distinct',
              title: 'Pact',
              name: 'Previous distinct version of this pact'})
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
            expect(subject[:_links][:'pb:latest-pact-version'][:title]).to eq "Pact"
            expect(subject[:_links][:'pb:latest-pact-version'][:name]).to eq "Latest version of this pact"
            expect(subject[:_links][:'pb:latest-pact-version'][:href]).to eq "http://example.org/pacts/provider/A%20Provider/consumer/A%20Consumer/latest"
          end

          xit "includes a link to the pact versions" do
            expect(subject[:_links][:'pb:pact-versions'][:title]).to eq "All versions of the pact between A Consumer and A Provider"
            expect(subject[:_links][:'pb:pact-versions'][:href]).to eq "http://example.org/pacts/provider/A%20Provider/consumer/A%20Consumer/versions"
          end

          it "includes a link to publish a verification" do
            expect(subject[:_links][:'pb:publish-verification-result'][:href]).to match %r{http://example.org/.*/verification-results}
          end

          it "includes a curie" do
            expect(subject[:_links][:curies]).to eq [{ name: "pb", href: "http://example.org/doc/{rel}", templated: true }]
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
