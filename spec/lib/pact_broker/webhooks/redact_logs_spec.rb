require 'pact_broker/webhooks/redact_logs'

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
      end
    end
  end
end
