require "rack/pact_broker/request_target"

module Rack
  module PactBroker
    describe RequestTarget do
      let(:rack_env) do
        {
          "CONTENT_TYPE" => content_type,
          "HTTP_ACCEPT" => accept,
          "PATH_INFO" => path
        }
      end
      let(:content_type) { nil }
      let(:accept) { nil }
      let(:path) { "" }

      describe "#request_for_ui?" do
        let(:path) { "/" }

        subject { RequestTarget.request_for_ui?(rack_env) }

        context "when the Accept header includes text/html" do
          let(:accept) { "text/html" }

          it { is_expected.to be true }
        end

        context "when the request is for a web asset with an Accept header of */*" do
          let(:path) { "/blah/foo.woff" }
          let(:accept) { "*/*" }

          it { is_expected.to be true }
        end

        context "when the request is for a content type served by the API (HAL browser request)" do
          let(:accept) { "application/hal+json, application/json, */*; q=0.01" }

          it { is_expected.to be false }
        end

        context "when the request is not for a web asset and the Accept headers is */* (default Accept header from curl request)" do
          let(:accept) { "*/*" }

          it { is_expected.to be false }
        end

        context "when the request is not for a web asset and no Accept header is specified" do
          let(:accept) { nil }

          it { is_expected.to be false }
        end

        context "when the request ends in a web asset extension but has Accept application/hal+json" do
          let(:accept) { "application/hal+json" }
          let(:path) { "/blah/foo.woff" }

          it { is_expected.to be false }
        end

        context "when the request is for a badge resource with a svg content type" do
          let(:accept) { "image/svg+xml;charset=utf-8" }
          let(:path) { "/pacts/provider/foo/consumer/bar/latest/badge" }

          it { is_expected.to be false }
        end
      end
    end
  end
end
