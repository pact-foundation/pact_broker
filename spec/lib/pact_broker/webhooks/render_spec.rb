require 'pact_broker/webhooks/render'
require 'cgi'

module PactBroker
  module Webhooks
    describe Render do
      describe "#call" do
        before do
          allow(PactBroker::Api::PactBrokerUrls).to receive(:pact_url).and_return("http://foo")
          allow(PactBroker::Api::PactBrokerUrls).to receive(:verification_url) do | verification, base_url |
            expect(verification).to_not be nil
            "http://verification"
          end
        end

        let(:pact) do
          instance_double("pact", consumer_version_number: "1.2.3+foo", consumer_name: "Foo", provider_name: "Bar", latest_verification: nil)
        end

        let(:pact_with_no_verification) { pact }

        let(:pact_with_successful_verification) do
          instance_double("pact",
            consumer_version_number: "1.2.3+foo",
            consumer_name: "Foo",
            provider_name: "Bar",
            latest_verification: verification)
        end

        let(:pact_with_failed_verification) do
          instance_double("pact",
            consumer_version_number: "1.2.3+foo",
            consumer_name: "Foo",
            provider_name: "Bar",
            latest_verification: failed_verification)
        end

        let(:verification) do
          instance_double("verification", provider_version_number: "3", success: true)
        end

        let(:failed_verification) do
          instance_double("verification", provider_version_number: "3", success: false)
        end

        let(:nil_pact) { nil }
        let(:nil_verification) { nil }

        subject { Render.call(template, pact, verification) }

        TEST_CASES = [
          ["${pactbroker.pactUrl}", "http://foo", :pact, :verification],
          ["${pactbroker.consumerVersionNumber}", "1.2.3+foo", :pact, :verification],
          ["${pactbroker.providerVersionNumber}", "3", :pact, :verification],
          ["${pactbroker.providerVersionNumber}", "", :pact, :nil_verification],
          ["${pactbroker.consumerName}", "Foo", :pact, :verification],
          ["${pactbroker.providerName}", "Bar", :pact, :verification],
          ["${pactbroker.githubVerificationStatus}", "success", :pact, :verification],
          ["${pactbroker.githubVerificationStatus}", "failure", :pact, :failed_verification],
          ["${pactbroker.githubVerificationStatus}", "", :nil_pact, :nil_verification],
          ["${pactbroker.githubVerificationStatus}", "pending", :pact_with_no_verification, :nil_verification],
          ["${pactbroker.githubVerificationStatus}", "success", :pact_with_successful_verification, :nil_verification],
          ["${pactbroker.githubVerificationStatus}", "failure", :pact_with_failed_verification, :nil_verification],
          ["${pactbroker.verificationResultUrl}", "", :pact_with_no_verification, :nil_verification],
          ["${pactbroker.verificationResultUrl}", "http://verification", :pact_with_successful_verification, :nil_verification],
          ["${pactbroker.verificationResultUrl}", "http://verification", :pact_with_successful_verification, :verification],
        ]

        TEST_CASES.each do | (template, expected_output, pact_var_name, verification_var_name) |
          context "with #{pact_var_name} and #{verification_var_name}" do
            it "replaces #{template} with #{expected_output.inspect}" do
              the_pact = send(pact_var_name)
              the_verification = send(verification_var_name)
              output = Render.call(template, the_pact, the_verification)
              expect(output).to eq expected_output
            end
          end
        end

        context "with an escaper" do
          subject do
            Render.call(template, pact, verification) do | value |
              CGI.escape(value)
            end
          end
          let(:template) do
            "${pactbroker.pactUrl}"
          end

          it { is_expected.to eq "http%3A%2F%2Ffoo" }
        end
      end
    end
  end
end
