require 'pact_broker/api/decorators/verification_decorator'

module PactBroker
  module Api
    module Decorators
      describe VerificationDecorator do

        let(:verification) do
          instance_double('PactBroker::Domain::Verification',
            number: 1,
            success: true,
            provider_version: "4.5.6",
            provider_name: 'Provider',
            consumer_name: 'Consumer',
            build_url: 'http://build-url',
            pact_version_content: pact_version_content,
            latest_pact_revision: pact_revision)
        end

        let(:pact_version_content) do
          instance_double('PactBroker::Pacts::PactVersionContent',
            name: 'A pact',
            provider_name: 'Provider',
            consumer_name: 'Consumer',
            sha: '1234',
            latest_consumer_version_number: '1.2.3'
          )
        end

        let(:pact_revision) do
          instance_double('PactBroker::Pacts::PactRevision',
            provider_name: 'Provider',
            consumer_name: 'Consumer',
            consumer_version_number: '1.2.3'
          )
        end

        let(:options) { { user_options: { base_url: 'http://example.org' } } }

        subject { JSON.parse VerificationDecorator.new(verification).to_json(options), symbolize_names: true }

        it "includes the success status" do
          expect(subject[:success]).to eq true
        end

        it "includes the provider version" do
          expect(subject[:providerVersion]).to eq "4.5.6"
        end

        it "includes the build URL" do
          expect(subject[:buildUrl]).to eq "http://build-url"
        end

        it "includes a link to itself" do
          expect(subject[:_links][:self][:href]).to match %r{http://example.org/.*/verifications/1}
        end

        it "includes a link to its pact" do
          expect(subject[:_links][:'pb:pact-version'][:href]).to match %r{http://example.org/pacts/}
        end
      end
    end
  end
end
