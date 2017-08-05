require 'pact_broker/webhooks/status'

module PactBroker
  module Webhooks
    describe Status do
      let(:webhooks) { [double('webhook')]}
      let(:webhook_executions) { [ first_execution, last_execution] }
      let(:first_execution) { double('webhook_execution') }
      let(:last_execution) { double('webhook_execution', success: last_execution_success) }
      let(:last_execution_success) { true }

      before do
        allow(webhook_executions).to receive(:sort).and_return(webhook_executions)
      end

      subject { Status.new(webhooks, webhook_executions) }

      context "when there are no webhooks configured" do
        let(:webhooks) { [] }
        its(:to_sym) { is_expected.to eq :none }
      end

      context "when there are no executions" do
        let(:webhook_executions) { [] }
        its(:to_sym) { is_expected.to eq :not_run }
      end

      context "when the most recent execution is successful" do
        its(:to_sym) { is_expected.to eq :success }
      end
    end
  end
end
