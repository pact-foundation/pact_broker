require "pact_broker/api/decorators/verification_decorator"

module PactBroker
  module Api
    module Decorators
      describe VerificationDecorator do
        before do
          allow_any_instance_of(VerificationDecorator).to receive(:verification_triggered_webhooks_url).and_return("http://triggered-webhooks")
        end

        let(:verification) do
          instance_double("PactBroker::Domain::Verification",
            number: 1,
            success: true,
            provider_version_number: "4.5.6",
            provider_name: "Provider",
            consumer_name: "Consumer",
            test_results: { "arbitrary" => "json" },
            build_url: "http://build-url",
            pact_version_sha: "1234",
            latest_pact_publication: pact_publication,
            execution_date: DateTime.now,
            provider_version_tags: provider_version_tags)
        end

        let(:pact_publication) do
          instance_double("PactBroker::Pacts::PactPublication",
            name: "A name",
            provider_name: "Provider",
            consumer_name: "Consumer",
            consumer_version_number: "1.2.3"
          )
        end

        let(:provider_version_tags) { [instance_double(PactBroker::Tags::TagWithLatestFlag, name: "prod", latest?: true)] }

        let(:options) { { user_options: { base_url: "http://example.org" } } }

        let(:json) { VerificationDecorator.new(verification).to_json(options) }

        subject { JSON.parse json, symbolize_names: true }

        it "includes the success status" do
          expect(subject[:success]).to eq true
        end

        it "includes the provider version" do
          expect(subject[:providerApplicationVersion]).to eq "4.5.6"
        end

        it "includes the test results" do
          expect(subject[:testResults]).to eq(arbitrary: "json")
        end

        it "includes the build URL" do
          expect(subject[:buildUrl]).to eq "http://build-url"
        end

        it "includes a link to itself" do
          expect(subject[:_links][:self][:href]).to match %r{http://example.org/.*/verification-results/1}
        end

        it "includes a link to its pact" do
          expect(subject[:_links][:'pb:pact-version'][:href]).to match %r{http://example.org/pacts/}
        end

        it "includes a link to the triggered webhooks" do
          expect(subject[:_links][:'pb:triggered-webhooks'][:href]).to eq "http://triggered-webhooks"
        end
      end
    end
  end
end
