require 'pact_broker/webhooks/status'

module PactBroker
  module Webhooks
    describe Status do
      let(:webhooks) { [double('webhook')]}
      let(:latest_triggered_webhooks) { [ triggered_webhook_1, triggered_webhook_2] }
      let(:pact) { double('pact') }
      let(:triggered_webhook_1) { double('triggered_webhook', status: status_1) }
      let(:triggered_webhook_2) { double('triggered_webhook', status: status_2) }
      let(:status_1) { TriggeredWebhook::STATUS_SUCCESS }
      let(:status_2) { TriggeredWebhook::STATUS_SUCCESS }

      subject { Status.new(pact, webhooks, latest_triggered_webhooks) }

      context "when there are no webhooks configured" do
        let(:webhooks) { [] }
        its(:to_sym) { is_expected.to eq :none }
      end

      context "when there are webhooks, but no triggered webhooks" do
        let(:latest_triggered_webhooks) { [] }
        its(:to_sym) { is_expected.to eq :not_run }
      end

      context "when all the triggered_webhooks are not_run" do
        let(:status_1) { TriggeredWebhook::STATUS_NOT_RUN }
        let(:status_2) { TriggeredWebhook::STATUS_NOT_RUN }
        its(:to_sym) { is_expected.to eq :not_run }
      end

      context "when the most recent triggered webhooks are successful" do
        its(:to_sym) { is_expected.to eq :success }
      end

      context "when one of the most recent executions is a failure" do
        let(:status_1) { TriggeredWebhook::STATUS_FAILURE }
        its(:to_sym) { is_expected.to eq :failure }
      end

      context "when one of the most recent executions is a failure and one is retrying" do
        let(:status_1) { TriggeredWebhook::STATUS_FAILURE }
        let(:status_2) { TriggeredWebhook::STATUS_RETRYING }
        its(:to_sym) { is_expected.to eq :retrying }
      end

      context "when the most recent executions are failures" do
        let(:status_1) { TriggeredWebhook::STATUS_FAILURE }
        let(:status_2) { TriggeredWebhook::STATUS_FAILURE }
        its(:to_sym) { is_expected.to eq :failure }
      end
    end
  end
end
