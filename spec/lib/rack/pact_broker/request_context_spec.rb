require "rack/pact_broker/request_context"
require "semantic_logger"

module Rack
  module PactBroker
    describe RequestContext do
      let(:captured) { {} }
      let(:inner_app) do
        captured_hash = captured
        lambda do | env |
          captured_hash[:named_tags] = SemanticLogger.named_tags
          captured_hash[:env] = env
          [200, {}, ["ok"]]
        end
      end
      let(:app) { RequestContext.new(inner_app) }

      it "tags the request with a generated request id" do
        app.call({})

        expect(captured[:named_tags][:request_id]).to match(/\A[0-9a-f]{32}\z/)
      end

      it "reuses an inbound request id, so a correlation id from a proxy is preserved" do
        app.call({ "HTTP_X_REQUEST_ID" => "from-upstream" })

        expect(captured[:named_tags][:request_id]).to eq "from-upstream"
      end

      it "puts the resolved request id into the rack env for downstream code" do
        app.call({})

        expect(captured[:env]["HTTP_X_REQUEST_ID"]).to eq captured[:named_tags][:request_id]
      end

      it "echoes the request id on the response" do
        _status, headers, _body = app.call({})

        expect(headers["x-request-id"]).to eq captured[:named_tags][:request_id]
      end

      it "does not violate Rack::Lint's lowercase header name rule" do
        env = Rack::MockRequest.env_for("/")
        linted_app = Rack::Lint.new(RequestContext.new(inner_app))

        expect { linted_app.call(env) }.to_not raise_error
      end

      it "returns the inner app's status and body untouched" do
        status, _headers, body = app.call({})

        expect(status).to eq 200
        expect(body).to eq ["ok"]
      end

      it "does not leak the tag outside the request" do
        app.call({})

        expect(SemanticLogger.named_tags).to eq({})
      end

      it "generates a different id per request" do
        app.call({})
        first = captured[:named_tags][:request_id]
        app.call({})

        expect(captured[:named_tags][:request_id]).to_not eq first
      end

      it "honours a well formed inbound request id verbatim" do
        _status, headers, _body = app.call({ "HTTP_X_REQUEST_ID" => "abc-123_XYZ.789" })

        expect(captured[:named_tags][:request_id]).to eq "abc-123_XYZ.789"
        expect(headers["x-request-id"]).to eq "abc-123_XYZ.789"
      end

      it "rejects an inbound request id containing CRLF and generates a fresh one instead" do
        _status, headers, _body = app.call({ "HTTP_X_REQUEST_ID" => "abc\r\nX-Injected: evil" })

        expect(captured[:named_tags][:request_id]).to match(/\A[0-9a-f]{32}\z/)
        expect(headers["x-request-id"]).to match(/\A[0-9a-f]{32}\z/)
      end

      it "rejects an inbound request id containing other control characters and generates a fresh one instead" do
        _status, headers, _body = app.call({ "HTTP_X_REQUEST_ID" => "abc\x00def" })

        expect(captured[:named_tags][:request_id]).to match(/\A[0-9a-f]{32}\z/)
        expect(headers["x-request-id"]).to match(/\A[0-9a-f]{32}\z/)
      end

      it "rejects an inbound request id longer than the maximum length and generates a fresh one instead" do
        _status, headers, _body = app.call({ "HTTP_X_REQUEST_ID" => "a" * 100_000 })

        expect(captured[:named_tags][:request_id]).to match(/\A[0-9a-f]{32}\z/)
        expect(headers["x-request-id"]).to match(/\A[0-9a-f]{32}\z/)
      end

      it "treats an empty inbound request id as absent and generates a fresh one instead" do
        _status, headers, _body = app.call({ "HTTP_X_REQUEST_ID" => "" })

        expect(captured[:named_tags][:request_id]).to match(/\A[0-9a-f]{32}\z/)
        expect(headers["x-request-id"]).to match(/\A[0-9a-f]{32}\z/)
      end
    end
  end
end
