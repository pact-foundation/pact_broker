require "spec_helper"
require "pact_broker/build_http_options"

module PactBroker
  describe BuildHttpOptions do

    subject { PactBroker::BuildHttpOptions.call(url, **options) }
    let(:options) { {} }

    context "default http options" do
      let(:options) { { disable_ssl_verification: false } }

      describe "when given an insecure URL" do
        let(:url) { "http://example.org/insecure" }

        it "should provide an empty configuration object" do
          expect(subject).to eq({})
        end

      end

      describe "when given a secure URL" do
        let(:url) { "https://example.org/secure" }

        it "should validate the full certificate chain" do
          expect(subject).to include({:use_ssl => true, :verify_mode => 1})
        end

      end
    end

    context "disable_ssl_verification is set to true" do
      let(:options) { { disable_ssl_verification: true } }

      let(:url) { "https://example.org/secure" }

      describe "when given a secure URL" do
        it "should not validate certificates" do
          expect(subject).to include({:use_ssl => true, :verify_mode => 0})
        end
      end
    end
  end
end
