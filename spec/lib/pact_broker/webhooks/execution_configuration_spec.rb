require 'pact_broker/webhooks/execution_configuration'

module PactBroker
  module Webhooks
    describe ExecutionConfiguration do
      subject { ExecutionConfiguration.new }

      it "returns a new object with the updated value" do
        expect(subject.with_show_response(true)[:logging_options][:show_response]).to eq true
        expect(subject.with_show_response(false)[:logging_options][:show_response]).to eq false
      end

      it "deep merges webhook context" do
        expect(subject.with_webhook_context(a: 1, b: 1).with_webhook_context(b: 2)[:webhook_context]).to eq a: 1, b: 2
      end
    end
  end
end
