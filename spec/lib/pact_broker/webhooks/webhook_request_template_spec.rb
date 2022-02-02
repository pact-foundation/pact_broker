require "pact_broker/webhooks/webhook_request_template"

module PactBroker
  module Webhooks
    describe WebhookRequestTemplate do
      let(:attributes) do
        {
          method: "POST",
          url: url,
          username: username,
          password: password,
          uuid: "1234",
          body: body,
          headers: headers
        }
      end

      let(:new_attributes) do
        {
          method: "POST",
          url: built_url,
          username: "usernameBUILT",
          password: "passwordBUILT",
          uuid: "1234",
          body: built_body,
          headers: {"headername" => "headervalueBUILT"},
          user_agent: "Pact Broker",
          disable_ssl_verification: true
        }
      end

      let(:username) { "username" }
      let(:password) { "password" }
      let(:headers) { {"headername" => "headervalue"} }
      let(:url) { "http://example.org/hook?foo=bar" }
      let(:base_url) { "http://broker" }
      let(:built_url) { "http://example.org/hook?foo=barBUILT" }
      let(:body) { { foo: "bar" } }
      let(:built_body) { '{"foo":"bar"}BUILT' }

      describe "#build" do
        before do
          allow(PactBroker::Webhooks::Render).to receive(:call) do | content, _pact, _verification |
            content + "BUILT"
          end
        end

        let(:params_hash) { double("params hash") }

        subject { WebhookRequestTemplate.new(attributes).build(params_hash, user_agent: "Pact Broker", disable_ssl_verification: true) }

        it "renders the url template" do
          expect(PactBroker::Webhooks::Render).to receive(:call).with(url, params_hash) do | content, pact, verification, &block |
            expect(content).to eq url
            expect(pact).to be pact
            expect(verification).to be verification
            expect(block.call("foo bar")).to eq "foo+bar"
            built_url
          end
          subject
        end

        context "when the body is a string" do
          let(:body) { "body" }

          it "renders the body template with the String" do
            expect(PactBroker::Webhooks::Render).to receive(:call).with("body", params_hash)
            subject
          end
        end

        context "when the body is an object" do
          let(:request_body_string) { '{"foo":"bar"}' }

          it "renders the body template with JSON" do
            expect(PactBroker::Webhooks::Render).to receive(:call).with(request_body_string, params_hash)
            subject
          end
        end

        it "renders each header value" do
          expect(PactBroker::Webhooks::Render).to receive(:call).with("headervalue", params_hash)
          subject
        end

        it "renders the username" do
          expect(PactBroker::Webhooks::Render).to receive(:call).with("username", params_hash)
          subject
        end

        it "renders the password" do
          expect(PactBroker::Webhooks::Render).to receive(:call).with("password", params_hash)
          subject
        end

        it "creates a new PactBroker::Domain::WebhookRequest" do
          expect(PactBroker::Domain::WebhookRequest).to receive(:new).with(new_attributes)
          subject
        end

        context "when optional attributes are missing" do
          let(:attributes) do
            {
              method: "POST",
              url: url,
              uuid: "1234",
            }
          end

          it "does not blow up" do
            subject
          end
        end
      end

      describe "redacted_headers" do
        subject { WebhookRequestTemplate.new(attributes) }

        let(:headers) do
          {
            "Authorization" => "foo",
            "X-authorization" => "bar",
            "Token" => "bar",
            "X-Auth-Token" => "bar",
            "X-Authorization-Token" => "bar",
            "OK" => "ok"
          }
        end

        let(:expected_headers) do
          {
            "Authorization" => "**********",
            "X-authorization" => "**********",
            "Token" => "**********",
            "X-Auth-Token" => "**********",
            "X-Authorization-Token" => "**********",
            "OK" => "ok"
          }
        end

        it "redacts sensitive headers" do
          expect(subject.redacted_headers).to eq expected_headers
        end

        context "when there is a parameter in the value" do
          let(:headers) do
            {
              "Authorization" => "${pactbroker.secret}"
            }
          end

          let(:expected_headers) do
            {
              "Authorization" => "${pactbroker.secret}"
            }
          end

          it "does not redact it" do
            expect(subject.redacted_headers).to eq expected_headers
          end
        end
      end

      describe "display_password" do
        subject { WebhookRequestTemplate.new(attributes) }

        context "when it is nil" do
          let(:password) { nil }

          its(:display_password) { is_expected.to be nil }
        end

        context "when the password contains a parameter" do
          let(:password) { "${pactbroker.foo}" }

          its(:display_password) { is_expected.to eq password }
        end

        context "when the password does not contains a parameter" do
          let(:password) { "foo" }

          its(:display_password) { is_expected.to eq "**********" }
        end
      end

      describe "template_parameters" do
        subject { WebhookRequestTemplate.new(attributes) }

        context "with a JSON body" do
          let(:url) { "http://localhost?token=${bar.thing}"}
          let(:body) do
            {
              "someKey" => "${pactbroker.something}",
              "${pactbroker.someKey}" => "blah",
              "blah" => "${foo.someFoo}"
            }
          end
          let(:headers) do
            {
              "name" => "${header.thing}"
            }
          end

          let(:username) { "${foo.username}" }
          let(:password) { "${foo.password}" }

          its(:template_parameters) { is_expected.to eq ["pactbroker.something", "pactbroker.someKey", "foo.someFoo", "bar.thing", "header.thing", "foo.username", "foo.password"] }
          its(:body_template_parameters) { is_expected.to eq ["pactbroker.something", "pactbroker.someKey", "foo.someFoo"] }
          its(:header_template_parameters) { is_expected.to eq ["header.thing"] }
          its(:url_template_parameters) { is_expected.to eq ["bar.thing"] }
          its(:credentials_template_parameters) { is_expected.to eq ["foo.username", "foo.password"]}

          context "with a scope specified" do
            it "returns the template_parameters that start with the specified scope" do
              expect(subject.template_parameters("foo")).to eq ["foo.someFoo", "foo.username", "foo.password"]
            end
          end
        end

        context "with a string body" do
          let(:body) { "${pactbroker.someKey} ${pactbroker.someOtherKey} ${pactbroker.someOtherKey} ${pactbroker.withSpace } pactbroker.invalid" }

          its(:template_parameters) { is_expected.to eq ["pactbroker.someKey", "pactbroker.someOtherKey"] }
        end
      end
    end
  end
end
