require 'rack/pact_broker/set_base_url'

module Rack
  module PactBroker
    describe SetBaseUrl do
      let(:base_urls) { ["http://pact-broker"] }
      let(:rack_env) { {} }
      let(:target_app) { double('app', call: [200, {}, []]) }
      let(:app) { SetBaseUrl.new(target_app, base_urls) }

      subject { get("/", {}, rack_env) }

      describe "#call" do
        context "when the base_url is already set" do
          let(:rack_env) { { "pactbroker.base_url" => "http://foo"} }

          it "does not overwrite it" do
            expect(target_app).to receive(:call).with(hash_including("pactbroker.base_url" => "http://foo"))
            subject
          end
        end

        context "when there is one base URL" do
          it "sets that base_url" do
            expect(target_app).to receive(:call).with(hash_including("pactbroker.base_url" => "http://pact-broker"))
            subject
          end
        end

        context "when there are no base URLs" do
          let(:base_urls) { [] }

          it "sets the base URL to nil" do
            expect(target_app).to receive(:call).with(hash_including("pactbroker.base_url" => nil))
            subject
          end
        end

        context "when there are multiple base URLs" do
          let(:base_urls) { ["https://foo", "https://pact-broker-external", "http://pact-broker-internal"] }

          let(:host) { "pact-broker-internal" }
          let(:scheme) { "http" }
          let(:forwarded_host) { "pact-broker-external" }
          let(:forwarded_scheme) { "https" }
          let(:rack_env) do
            {
              Rack::HTTP_HOST => host,
              Rack::RACK_URL_SCHEME => scheme,
              "HTTP_X_FORWARDED_HOST" => forwarded_host,
              "HTTP_X_FORWARDED_SCHEME" => forwarded_scheme
            }
          end

          context "when the base URL created taking any X-Forwarded headers into account matches one of the base URLs" do
            it "uses that base URL" do
              expect(target_app).to receive(:call).with(hash_including("pactbroker.base_url" => "https://pact-broker-external"))
              subject
            end
          end

          context "when the base URL created NOT taking the X-Forwarded headers into account matches one of the base URLs (potential cache poisoning)" do
            let(:forwarded_host) { "pact-broker-external-wrong" }

            it "uses that base URL" do
              expect(target_app).to receive(:call).with(hash_including("pactbroker.base_url" => "http://pact-broker-internal"))
              subject
            end
          end

          context "when neither base URL matches the base URLs (potential cache poisoning)" do
            before do
              rack_env["HTTP_HOST"] = "silly-buggers-1"
              rack_env["HTTP_X_FORWARDED_HOST"] = "silly-buggers-1"
            end

            it "uses the first base URL" do
              expect(target_app).to receive(:call).with(hash_including("pactbroker.base_url" => "https://foo"))
              subject
            end
          end
        end
      end
    end
  end
end
