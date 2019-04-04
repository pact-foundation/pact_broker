require 'rack/pact_broker/accepts_html_filter'
require 'rack/test'

module Rack
  module PactBroker
    describe AcceptsHtmlFilter do
      include Rack::Test::Methods

      describe "#call" do
        let(:target_app) { double('target_app', call: [200, {}, []]) }
        let(:app) { AcceptsHtmlFilter.new(target_app) }
        let(:path) { "/" }
        let(:accept) { "text/html" }

        subject { get path, nil, { "HTTP_ACCEPT" => accept } }

        context "when the Accept header includes text/html" do
          it "forwards the request to the target app" do
            expect(target_app).to receive(:call)
            subject
          end
        end

        context "when the request is for a file" do
          let(:path) { "/blah/foo.css" }

          it "forwards the request to the target app" do
            expect(target_app).to receive(:call)
            subject
          end
        end

        context "when the request is not for a file, and the Accept header does not include text/html" do
          let(:accept) { "application/hal+json, */*" }

          it "returns a 404" do
            expect(subject.status).to eq 404
          end
        end
      end
    end
  end
end
