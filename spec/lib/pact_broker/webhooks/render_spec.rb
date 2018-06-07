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
          "Foo ${pactbroker.pactUrl} ${pactbroker.consumerVersionNumber}"
        end

        let(:pact) do
          instance_double("pact", consumer_version_number: "1.2.3+foo")
        end

        subject { Render.call(body, pact, nil) }

        it { is_expected.to eq "Foo http://foo 1.2.3+foo" }

        context "with an escaper" do
          subject do
            Render.call(body, pact, nil) do | value |
              CGI.escape(value)
            end
          end

          it { is_expected.to eq "Foo http%3A%2F%2Ffoo 1.2.3%2Bfoo" }
        end
      end
    end
  end
end
