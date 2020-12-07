require 'pact_broker/api/decorators/extended_pact_decorator'

module PactBroker
  module Api
    module Decorators
      describe ExtendedPactDecorator do
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
          consumer_name: consumer.name,
          provider: provider,
          provider_name: provider.name,
          consumer_version: consumer_version,
          consumer_version_number: '1234',
          pact_version_sha: '9999',
          revision_number: 2,
          name: 'A Pact',
          head_tag_names: head_tag_names
        )}
        let(:head_tag_names) { ['prod'] }
        let(:consumer) { instance_double(PactBroker::Domain::Pacticipant, name: 'A Consumer')}
        let(:provider) { instance_double(PactBroker::Domain::Pacticipant, name: 'A Provider')}
        let(:consumer_version) { instance_double(PactBroker::Domain::Version, number: '1234', pacticipant: consumer)}
        let(:metadata) { "abcd" }
        let(:decorator) { ExtendedPactDecorator.new(pact) }
        let(:json) { decorator.to_json(user_options: { base_url: base_url, metadata: metadata }) }
        subject { JSON.parse(json, symbolize_names: true) }

        it "includes an array of tags" do
          expect(subject[:_embedded][:tags].first).to include name: 'prod', latest: true
          # Can't seem to stub the verification_publication_url method on the TagDecorator
          expect(subject[:_embedded][:tags].first[:_links][:'pb:latest-pact'][:href]).to eq "http://example.org/pacts/provider/A%20Provider/consumer/A%20Consumer/latest/prod"
          expect(subject[:_embedded][:tags].first[:_links][:self][:href]).to eq "http://example.org/pacticipants/A%20Consumer/versions/1234/tags/prod"
        end

        it "includes the pact contents under the contract key" do
          expect(subject[:contract]).to eq JSON.parse(content_hash.to_json, symbolize_names: true)
        end

        it "does not include the contract contents in the root" do
          expect(subject).to_not have_key(:interactions)
        end
      end
    end
  end
end
