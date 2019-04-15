require 'rack/pact_broker/ui_request_filter'
require 'rack/test'

module Rack
  module PactBroker
    describe UIRequestFilter do
      include Rack::Test::Methods

      describe "#call" do
        let(:target_app) { double('target_app', call: [200, {}, []]) }
        let(:app) { UIRequestFilter.new(target_app) }
        let(:path) { "/" }
        let(:accept) { "text/html" }

        subject { get path, nil, { "HTTP_ACCEPT" => accept } }

        context "when the Accept header includes text/html" do
          it "forwards the request to the target app" do
            expect(target_app).to receive(:call)
            subject
          end
        end

        context "when the request is for a web asset with an Accept header of */*" do
          let(:path) { "/blah/foo.woff" }
          let(:accept) { "*/*" }

          it "forwards the request to the target app" do
            expect(target_app).to receive(:call)
            subject
          end
        end

        context "when the request is for a content type served by the API (HAL browser request)" do
          let(:accept) { "application/hal+json, application/json, */*; q=0.01" }

          it "returns a 404" do
            expect(subject.status).to eq 404
          end
        end

        context "when the request is not for a web asset and the Accept headers is */* (default Accept header from curl request)" do
          let(:accept) { "*/*" }

          it "returns a 404" do
            expect(subject.status).to eq 404
          end
        end

        context "when the request is not for a web asset and no Accept header is specified" do
          let(:accept) { nil }

          it "returns a 404" do
            expect(subject.status).to eq 404
          end
        end
      end
    end
  end
end
