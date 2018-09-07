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

      context "when the whitelist includes *.foo.bar" do
        let(:whitelist) { ["*.foo.bar"] }

        it "matches host a.foo.bar" do
          expect(CheckHostWhitelist.call("a.foo.bar", whitelist)).to eq whitelist
        end

        it "does not matche host a.b.foo.bar" do
          expect(CheckHostWhitelist.call("a.b.foo.bar", whitelist)).to eq []
        end

        it "does not match a.foo.bar.b" do
          expect(CheckHostWhitelist.call("a.foo.bar.b", whitelist)).to eq []
        end

        it "does not match foo.bar" do
          expect(CheckHostWhitelist.call("foo.bar", whitelist)).to eq []
        end

        it "does not match 10.0.0.2" do
          expect(CheckHostWhitelist.call("10.0.0.2", whitelist)).to eq []
        end
      end

      context "when the whitelist includes *.2" do
        it "does not match 10.0.0.2 as that's the wrong way to declare an IP range" do
          expect(CheckHostWhitelist.call("10.0.0.2", ["*.0.0.2"])).to eq []
        end
      end

      context "when the whitelist includes *.foo.*.bar" do
        let(:whitelist) { ["*.foo.*.bar"] }

        it "does not match host a.foo.b.bar, according to RFC 6125, section 6.4.3, subitem 1" do
          expect(CheckHostWhitelist.call("a.foo.b.bar", whitelist)).to eq []
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
