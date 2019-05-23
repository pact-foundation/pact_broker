require 'pact_broker/webhooks/render'
require 'pact_broker/pacts/placeholder_pact'
require 'pact_broker/verifications/placeholder_verification'
require 'cgi'

module PactBroker
  module Webhooks
    describe Render do
      describe "#call" do
        before do
          allow(PactBroker::Api::PactBrokerUrls).to receive(:pact_version_url_with_metadata).and_return("http://foo")
          allow(PactBroker::Api::PactBrokerUrls).to receive(:verification_url) do | verification, base_url |
            expect(verification).to_not be nil
            "http://verification"
          end
        end

        let(:base_url) { "http://broker" }

        let(:pact) do
          double("pact",
            consumer_version: consumer_version,
            consumer_version_number: "1.2.3+foo",
            consumer_name: "Foo",
            provider_name: "Bar",
            consumer: consumer,
            provider: provider,
            latest_verification: nil)
        end

        let(:pact_with_no_verification) { pact }

        let(:pact_with_successful_verification) do
          double("pact",
            consumer_version: consumer_version,
            consumer_version_number: "1.2.3+foo",
            consumer_name: "Foo",
            provider_name: "Bar",
            consumer: consumer,
            provider: provider,
            latest_verification: verification)
        end

        let(:pact_with_failed_verification) do
          double("pact",
            consumer_version: consumer_version,
            consumer_version_number: "1.2.3+foo",
            consumer_name: "Foo",
            provider_name: "Bar",
            consumer: consumer,
            provider: provider,
            latest_verification: failed_verification)
        end

        let (:provider) do
          double("provider", labels: provider_labels)
        end

        let (:consumer) do
          double("consumer", labels: consumer_labels)
        end

        let(:verification) do
          double("verification", provider_version_number: "3", success: true, provider_version: provider_version)
        end

        let(:failed_verification) do
          double("verification", provider_version_number: "3", success: false, provider_version: provider_version)
        end

        let(:provider_version) do
          double("version", tags: provider_tags)
        end

        let(:consumer_version) do
          double("version", tags: consumer_tags)
        end

        let(:provider_tags) do
          [ double("tag", name: "test"), double("tag", name: "prod") ]
        end

        let(:consumer_tags) do
          [ double("tag", name: "test") ]
        end

        let(:provider_labels) do
          [ double("label", name: "finance"), double("label", name: "IT") ]
        end

        let(:consumer_labels) do
          [ double("label", name: "foo"), double("label", name: "bar") ]
        end

        let(:webhook_context) { { base_url: base_url } }

        let(:nil_pact) { nil }
        let(:nil_verification) { nil }

        TEST_CASES = [
          ["${pactbroker.pactUrl}", "http://foo", :pact, :verification],
          ["${pactbroker.consumerVersionNumber}", "1.2.3+foo", :pact, :verification],
          ["${pactbroker.providerVersionNumber}", "3", :pact, :verification],
          ["${pactbroker.providerVersionNumber}", "", :pact, :nil_verification],
          ["${pactbroker.consumerName}", "Foo", :pact, :verification],
          ["${pactbroker.providerName}", "Bar", :pact, :verification],
          ["${pactbroker.githubVerificationStatus}", "success", :pact, :verification],
          ["${pactbroker.githubVerificationStatus}", "failure", :pact, :failed_verification],
          ["${pactbroker.githubVerificationStatus}", "pending", :nil_pact, :nil_verification],
          ["${pactbroker.githubVerificationStatus}", "pending", :pact_with_no_verification, :nil_verification],
          ["${pactbroker.githubVerificationStatus}", "success", :pact_with_successful_verification, :nil_verification],
          ["${pactbroker.githubVerificationStatus}", "failure", :pact_with_failed_verification, :nil_verification],
          ["${pactbroker.verificationResultUrl}", "", :pact_with_no_verification, :nil_verification],
          ["${pactbroker.verificationResultUrl}", "http://verification", :pact_with_successful_verification, :nil_verification],
          ["${pactbroker.verificationResultUrl}", "http://verification", :pact_with_successful_verification, :verification],
          ["${pactbroker.providerVersionTags}", "test, prod", :pact_with_successful_verification, :verification],
          ["${pactbroker.consumerVersionTags}", "test", :pact_with_successful_verification, :verification],
          ["${pactbroker.consumerLabels}", "foo, bar", :pact_with_successful_verification, :verification],
          ["${pactbroker.providerLabels}", "finance, IT", :pact, :nil_verification],
        ]

        TEST_CASES.each do | (template, expected_output, pact_var_name, verification_var_name) |
          context "with #{pact_var_name} and #{verification_var_name}" do
            it "replaces #{template} with #{expected_output.inspect}" do
              the_pact = send(pact_var_name)
              the_verification = send(verification_var_name)
              output = Render.call(template, the_pact, the_verification, webhook_context)
              expect(output).to eq expected_output
            end
          end
        end

        context "with an escaper" do
          subject do
            Render.call(template, pact, verification, webhook_context) do | value |
              CGI.escape(value)
            end
          end
          let(:template) do
            "${pactbroker.pactUrl}"
          end

          it { is_expected.to eq "http%3A%2F%2Ffoo" }
        end

        context "with webhook context data passed in" do
          let(:webhook_context) do
            {
              consumer_version_number: "webhook-version-number",
              consumer_version_tags: %w[webhook tags]
            }
          end

          it "uses the consumer_version_number in preference to the field on the domain models" do
            template = "${pactbroker.consumerVersionNumber}"
            output = Render.call(template, pact, verification, webhook_context)
            expect(output).to eq "webhook-version-number"
          end

          it "uses the consumer_version_tags in preference to the field on the domain models" do
            template = "${pactbroker.consumerVersionTags}"
            output = Render.call(template, pact, verification, webhook_context)
            expect(output).to eq "webhook, tags"
          end
        end
      end

      describe "#call with placeholder domain objects" do
        let(:placeholder_pact) { PactBroker::Pacts::PlaceholderPact.new }
        let(:placeholder_verification) { PactBroker::Verifications::PlaceholderVerification.new }
        let(:base_url) { "http://broker" }

        it "does not blow up with a placeholder pact" do
          Render.call("", placeholder_pact, nil, {})
        end

        it "does not blow up with a placeholder verification" do
          Render.call("", placeholder_pact, placeholder_verification, {})
        end
      end
    end
  end
end
