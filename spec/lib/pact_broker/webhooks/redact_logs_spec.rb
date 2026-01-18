require "pact_broker/webhooks/redact_logs"

module PactBroker
  module Webhooks
    describe RedactLogs do
      describe ".call" do
        let(:values) { [] }

        let(:string) do
          "Authorization: foo\nX-Thing: bar"
        end

        let(:x_auth_string) do
          "X-Authorization: bar foo\nX-Thing: bar"
        end

        let(:x_auth_token) do
          "X-Auth-Token: bar foo\nX-Thing: bar"
        end

        let(:x_authorization_token) do
          "X-Authorization-Token: bar foo\nX-Thing: bar"
        end

        let(:string_lower) do
          "authorization: foo\nX-Thing: bar"
        end

        it "hides the value of the Authorization header" do
          expect(RedactLogs.call(string, values)).to eq "Authorization: [REDACTED]\nX-Thing: bar"
        end

        it "hides the value of the X-Authorization header" do
          expect(RedactLogs.call(x_auth_string, values)).to eq "X-Authorization: [REDACTED]\nX-Thing: bar"
        end

        it "hides the value of the X-Auth-Token header" do
          expect(RedactLogs.call(x_auth_token, values)).to eq "X-Auth-Token: [REDACTED]\nX-Thing: bar"
        end

        it "hides the value of the X-Authorization-Token header" do
          expect(RedactLogs.call(x_authorization_token, values)).to eq "X-Authorization-Token: [REDACTED]\nX-Thing: bar"
        end

        it "hides the value of the authorization header" do
          expect(RedactLogs.call(string_lower, values)).to eq "authorization: [REDACTED]\nX-Thing: bar"
        end

        context "with values" do
          let(:values) { %w[foo bar] }
          let(:string) { "blahfoo\nbar wiffle" }

          it "hides the passed in values" do
            expect(RedactLogs.call(string, values)).to eq "blah********\n******** wiffle"
          end
        end

        context "with pattern_substitutions" do
          context "with pattern matching JSON keys" do
            let(:pattern_substitutions) { [[/("apiKey":\s*")([^"]+)/, '\1[REDACTED]']] }
            let(:string) { '{"apiKey": "abc123", "userId": "123"}' }

            it "redacts JSON values" do
              expect(RedactLogs.call(string, values, pattern_substitutions)).to eq '{"apiKey": "[REDACTED]", "userId": "123"}'
            end
          end

          context "with empty pattern_substitutions array" do
            let(:pattern_substitutions) { [] }
            let(:string) { "Authorization: secret\nOther: data" }

            it "still applies default HEADER_SUBSTITUTIONS" do
              expect(RedactLogs.call(string, values, pattern_substitutions)).to eq "Authorization: [REDACTED]\nOther: data"
            end
          end
        end

        context "with combined redactions (values + pattern_substitutions)" do
          let(:values) { ["supersecret"] }
          let(:pattern_substitutions) { [[/(api_token=)([^&\s]+)/, '\1[REDACTED]']] }
          let(:string) do
            "Authorization: Bearer supersecret\n" \
            "Request: /api?api_token=abc123\n" \
            "Token: xyz789"
          end

          it "applies all three types of redactions (HEADER_SUBSTITUTIONS, values, pattern_substitutions)" do
            expected = "Authorization: [REDACTED]\n" \
                      "Request: /api?api_token=[REDACTED]\n" \
                      "Token: [REDACTED]"
            expect(RedactLogs.call(string, values, pattern_substitutions)).to eq expected
          end
        end

        context "with complex real-world webhook scenarios" do
          let(:values) { ["mytoken123", "mysecret456"] }
          let(:pattern_substitutions) do
            [
              [/(client_secret=)([^&\s]+)/, '\1[REDACTED]'],
              [/("password":\s*")([^"]+)/, '\1[REDACTED]']
            ]
          end
          let(:string) do
            "POST /webhook HTTP/1.1\n" \
            "Authorization: Bearer mytoken123\n" \
            "X-Custom-Token: mysecret456\n" \
            'Body: {"username": "admin", "password": "pass123"}\n' \
            "Callback: https://example.com/oauth?client_secret=secret789"
          end

          it "redacts all sensitive information from webhook logs" do
            expected = "POST /webhook HTTP/1.1\n" \
                      "Authorization: [REDACTED]\n" \
                      "X-Custom-Token: [REDACTED]\n" \
                      'Body: {"username": "admin", "password": "[REDACTED]"}\n' \
                      "Callback: https://example.com/oauth?client_secret=[REDACTED]"
            expect(RedactLogs.call(string, values, pattern_substitutions)).to eq expected
          end
        end
      end
    end
  end
end
