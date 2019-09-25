require 'pact_broker/api/decorators/verification_summary_decorator'

module PactBroker
  module Api
    module Decorators
      describe VerificationSummaryDecorator do
        let(:summary) { instance_double("PactBroker::Verification::SummaryForConsumerVersion", verifications: verifications, success: true, provider_summary: provider_summary) }
        let(:provider_summary) {
          instance_double("provider summary", successful: ["Successful provider"], failed: ["Failed provider"], unknown: ["Unknown provider"])
        }
        let(:verifications) { [verification] }
        let(:verification) do
          instance_double("PactBroker::Domain::Verification",
            success: true, number: 1,
            provider_version_number: '4.5.6',
            build_url: 'http://some-build',
            provider_name: 'Provider',
            consumer_name: 'Consumer',
            pact_version: pact_version,
            pact_version_sha: '1234',
            latest_pact_publication: pact,
            test_results: nil,
            execution_date: DateTime.now,
            provider_version_tags: provider_version_tags)
        end
        let(:pact_version) do
          instance_double("PactBroker::Pacts::PactVersion", name: 'Name')
        end

        let(:provider_version_tags) { [instance_double(PactBroker::Tags::TagWithLatestFlag, name: 'prod', latest?: true)] }
        let(:pact) { instance_double("PactBroker::Domain::Pact", name: "Some pact", consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "1.2.3") }
        let(:options) { {base_url: 'http://example.org', consumer_name: "Foo", consumer_version_number: "1.2.3", resource_url: "http://self"} }

        subject { JSON.parse VerificationSummaryDecorator.new(summary).to_json(user_options: options), symbolize_names: true }

        it "includes a list of verification results" do
          expect(subject[:_embedded][:verificationResults]).to be_instance_of(Array)
          expect(subject[:_embedded][:verificationResults].size).to eq 1
        end

        it "includes a title" do
          expect(subject[:_links][:self][:title]).to eq "Latest verification results for consumer Foo version 1.2.3"
        end

        it "includes a link to itself" do
          expect(subject[:_links][:self][:href]).to eq "http://self"
        end

        it "includes a flag to indicate the overall success or failure of all the verification results" do
          expect(subject[:success]).to be true
        end

        it "includes a provider summary" do
          expect(subject[:providerSummary][:successful]).to eq ["Successful provider"]
          expect(subject[:providerSummary][:failed]).to eq ["Failed provider"]
          expect(subject[:providerSummary][:unknown]).to eq ["Unknown provider"]
        end
      end
    end
  end
end
