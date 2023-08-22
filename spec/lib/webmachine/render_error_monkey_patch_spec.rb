require "webmachine/render_error_monkey_patch"
require "webmachine/adapters/rack"

module Webmachine
  describe ".render_error" do
    let(:request) do
      r = Webmachine::Adapters::Rack::RackRequest.new("GET", "http://example.org/foo", request_headers, "", "", nil, rack_env)
      r.path_info = { application_context: PactBroker::ApplicationContext.default_application_context }
      r
    end
    let(:request_headers) { Webmachine::Headers.new }
    let(:response) { Webmachine::Response.new }
    let(:options) { {} }
    let(:rack_env) { { "pactbroker.application_context" => PactBroker::ApplicationContext.default_application_context, "pactbroker.base_url" => "http://example.org" }}

    subject { Webmachine.render_error(404, request, response, options); response }

    it "returns a JSON body" do
      expect(JSON.parse(subject.body)).to eq "error" => "The requested document was not found on this server."
    end

    its(:headers) { is_expected.to include("Content-Type" => "application/json;charset=utf-8") }

    context "when the Accept header contains text/html" do
      let(:request_headers) { Webmachine::Headers.from_cgi("HTTP_ACCEPT" => "text/html") }

      its(:headers) { is_expected.to include("Content-Type" => "text/html") }
      its(:body) { is_expected.to include("<html") }
      its(:body) { is_expected.to include("404 Not Found") }
      its(:body) { is_expected.to include("The requested document was not found on this server.") }
    end

    context "when the Accept header contains application/problem+json" do
      let(:request_headers) { Webmachine::Headers.from_cgi("HTTP_ACCEPT" => "application/problem+json") }

      let(:expected_body) do
        {
          "detail" => "The requested document was not found on this server.",
          "status" => 404,
          "title" => "404 Not Found",
          "type" => "http://example.org/problem/not-found"
        }
      end

      its(:headers) { is_expected.to include("Content-Type" => "application/problem+json;charset=utf-8") }

      it "returns a JSON body in problem json format" do
        expect(JSON.parse(subject.body)).to eq expected_body
      end

      context "with custom options" do
        let(:options) { { message: "hello world", title: "Title" } }

        let(:expected_body) do
          {
            "detail" => "hello world",
            "status" => 404,
            "title" => "Title",
            "type" => "http://example.org/problem/title"
          }
        end

        it "uses the custom message" do
          expect(JSON.parse(subject.body)).to eq expected_body
        end
      end
    end
  end
end
