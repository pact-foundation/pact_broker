require 'rack/pact_broker/hal_browser_redirect'

module Rack
  module PactBroker
    describe HalBrowserRedirect do
      let(:target_app) { ->(env){ [200, {}, []] } }
      let(:app) { HalBrowserRedirect.new(target_app) }
      let(:rack_env) do
        {
          "pactbroker.base_url" => "http://base/foo",
          "HTTP_ACCEPT" => "text/html"
        }
      end

      subject { get(path, nil, rack_env) }

      context "when requesting verification results" do
        let(:path) { "/pacts/provider/Bar/consumer/Foo/pact-version/a2456ade40d0e148e23fb3310ec56831fef6ce8e/verification-results/106" }

        it "redirects to the HAL browser" do
          expect(subject.status).to eq 303
          expect(subject.headers["Location"]).to eq "http://base/foo/hal-browser/browser.html#http://base/foo/pacts/provider/Bar/consumer/Foo/pact-version/a2456ade40d0e148e23fb3310ec56831fef6ce8e/verification-results/106"
        end
      end
    end
  end
end
