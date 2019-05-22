require 'pact_broker/webhooks/webhook_request_template'

module PactBroker
  module Webhooks
    describe WebhookRequestTemplate do
      let(:attributes) do
        {
          method: 'POST',
          url: url,
          username: "foo",
          password: "bar",
          uuid: "1234",
          body: body,
          headers: {'Foo' => 'bar'}
        }
      end

      let(:new_attributes) do
        {
          method: 'POST',
          url: built_url,
          username: "foo",
          password: "bar",
          uuid: "1234",
          body: built_body,
          headers: {'Foo' => 'bar'}
        }
      end

      let(:url) { "http://example.org/hook?foo=bar" }
      let(:base_url) { "http://broker" }
      let(:built_url) { "http://example.org/hook?foo=barBUILT" }
      let(:body) { { foo: "bar" } }
      let(:built_body) { '{"foo":"bar"}BUILT' }

      describe "#build" do
        before do
          allow(PactBroker::Webhooks::Render).to receive(:call) do | content, pact, verification, &block |
            content + "BUILT"
          end
        end

        let(:pact) { double('pact') }
        let(:verification) { double('verification') }
        let(:webhook_context) { { some: "context" } }
        let(:template_context) do
          {
            pact: pact,
            verification: verification,
            webhook_context: webhook_context
          }
        end
        subject { WebhookRequestTemplate.new(attributes).build(template_context) }

        it "renders the url template" do
          expect(PactBroker::Webhooks::Render).to receive(:call).with(url, pact, verification, webhook_context) do | content, pact, verification, &block |
            expect(content).to eq url
            expect(pact).to be pact
            expect(verification).to be verification
            expect(block.call("foo bar")).to eq "foo+bar"
            built_url
          end
          subject
        end

        context "when the body is a string" do
          let(:body) { 'body' }

          it "renders the body template with the String" do
            expect(PactBroker::Webhooks::Render).to receive(:call).with('body', pact, verification, webhook_context)
            subject
          end
        end

        context "when the body is an object" do
          let(:request_body_string) { '{"foo":"bar"}' }

          it "renders the body template with JSON" do
            expect(PactBroker::Webhooks::Render).to receive(:call).with(request_body_string, pact, verification, webhook_context)
            subject
          end
        end

        it "creates a new PactBroker::Domain::WebhookRequest" do
          expect(PactBroker::Domain::WebhookRequest).to receive(:new).with(new_attributes)
          subject
        end
      end
    end
  end
end
