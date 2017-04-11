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
            build_url: 'http://build-url',
            pact: pact)
        end

        let(:pact) do
          instance_double('PactBroker::Domain::Pact',
            name: 'A pact',
            provider: double(name: 'Provider'),
            consumer: double(name: 'Consumer'),
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
      end
    end
  end
end
