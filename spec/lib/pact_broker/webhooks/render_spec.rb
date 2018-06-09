require 'pact_broker/webhooks/render'
require 'cgi'

module PactBroker
  module Webhooks
    describe Render do
      describe "#call" do
        before do
          allow(PactBroker::Api::PactBrokerUrls).to receive(:pact_url).and_return("http://foo")
        end

        let(:body) do
          "Foo ${pactbroker.pactUrl} ${pactbroker.consumerVersionNumber} ${pactbroker.providerVersionNumber}"
        end

        let(:pact) do
          instance_double("pact", consumer_version_number: "1.2.3+foo")
        end

        let(:verification) do
          instance_double("verification", provider_version_number: "3")
        end

        subject { Render.call(body, pact, verification) }

        it { is_expected.to eq "Foo http://foo 1.2.3+foo 3" }


        context "when the verification is nil" do
          let(:verification) { nil }

          let(:body) do
            "${pactbroker.providerVersionNumber}"
          end

          it "inserts an empty string" do
            expect(subject).to eq ""
          end
        end

        context "with an escaper" do
          subject do
            Render.call(body, pact, verification) do | value |
              CGI.escape(value)
            end
          end

          it { is_expected.to eq "Foo http%3A%2F%2Ffoo 1.2.3%2Bfoo 3" }
        end
      end
    end
  end
end
