require "pact_broker/db/validate_encoding"
require "pact_broker/db"

module PactBroker
  module DB

    describe ValidateEncoding do

      let(:opts) { {encoding: encoding} }
      let(:connection) { double("connection", opts: opts)}

      subject { ValidateEncoding.(connection) }

      describe ".call" do
        context "when encoding is UTF8" do
          let(:encoding) { "UTF8" }

          it "does not raise an error" do
            subject
          end
        end

        context "when encoding is UTF8" do
          let(:encoding) { "utf8" }

          it "does not raise an error" do
            subject
          end
        end

        context "when encoding is utf-8" do
          let(:encoding) { "utf-8" }

          it "does not raise an error" do
            subject
          end
        end

        context "when encoding is utf-80" do
          let(:encoding) { "utf-80" }

          it "does not raise an error, maybe it should, ah well" do
            subject
          end
        end

        context "when encoding is null" do
          let(:encoding) { nil }

          it "raises an error" do
            expect{ subject }.to raise_error ConnectionConfigurationError, /The Sequel connection encoding \(nil\) is strongly recommended to be "utf8"/
          end
        end

        context "when encoding is latin1" do
          let(:encoding) { "latin1" }

          it "raises an error" do
            expect{ subject }.to raise_error ConnectionConfigurationError, /The Sequel connection encoding \("latin1"\) is strongly recommended to be "utf8"/
          end
        end
      end

    end
  end
end
