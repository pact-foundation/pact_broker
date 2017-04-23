require 'pact_broker/api/decorators/verifications_decorator'

module PactBroker
  module Api
    module Decorators
      describe VerificationsDecorator do
        let(:verifications) { [verification] }
        let(:verification) do
          instance_double("PactBroker::Domain::Verification",
            success: true, number: 1,
            provider_version: '4.5.6',
            build_url: 'http://some-build',
            latest_pact_revision: pact,
            provider_name: 'provider',
            consumer_name: 'consumer',
            pact_version_content: pact_version_content)
        end
        let(:pact_version_content) do
          instance_double("PactBroker::Pacts::PactVersionContent", sha: '1234', name: 'Name')
        end
        let(:pact) { instance_double("PactBroker::Domain::Pact", name: "Some pact", consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "1.2.3") }
        let(:options) { {base_url: 'http://example.org', consumer_name: "Foo", consumer_version_number: "1.2.3", resource_url: "http://self"} }

        subject { JSON.parse VerificationsDecorator.new(verifications).to_json(user_options: options), symbolize_names: true }

        it "includes a list of verifications" do
          expect(subject[:_embedded][:verifications]).to be_instance_of(Array)
          expect(subject[:_embedded][:verifications].size).to eq 1
        end

        it "includes a title" do
          expect(subject[:_links][:self][:title]).to eq "Latest verifications for consumer Foo version 1.2.3"
        end

        it "includes a link to itself" do
          expect(subject[:_links][:self][:href]).to eq "http://self"
        end
      end
    end
  end
end
