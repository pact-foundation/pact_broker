require 'pact_broker/webhooks/check_host_whitelist'

module PactBroker
  module Webhooks
    describe CheckHostWhitelist do
      context "when the host is 10.0.0.7" do
        let(:host) { "10.0.1.0" }

        it "matches 10.0.0.0/8" do
          expect(CheckHostWhitelist.call(host, ["10.0.0.0/8"])).to eq ["10.0.0.0/8"]
        end

        it "matches 10.0.1.0" do
          expect(CheckHostWhitelist.call(host, [host])).to eq [host]
        end

        it "does not match 10.0.0.2" do
          expect(CheckHostWhitelist.call(host, ["10.0.0.2"])).to eq []
        end

        it "does not match 10.0.0.0/28" do
          expect(CheckHostWhitelist.call(host, ["10.0.0.0/28"])).to eq []
        end
      end

      context "when the host is localhost" do
        let(:host) { "localhost" }

        it "matches localhost" do
          expect(CheckHostWhitelist.call(host, [host])).to eq [host]
        end

        it "matches /local.*/" do
          expect(CheckHostWhitelist.call(host, [/local*/])).to eq [/local*/]
        end

        it "does not match foo" do
          expect(CheckHostWhitelist.call(host, ["foo"])).to eq []
        end

        it "does not match /foo.*/" do
          expect(CheckHostWhitelist.call(host, [/foo*/])).to eq []
        end
      end
    end
  end
end
