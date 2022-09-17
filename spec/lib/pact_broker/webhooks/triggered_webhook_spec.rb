require "pact_broker/webhooks/triggered_webhook"

module PactBroker
  module Webhooks
    describe TriggeredWebhook do
      let(:status) { TriggeredWebhook::STATUS_SUCCESS }

      subject { TriggeredWebhook.new(status: status) }

      describe "remaining_attempts" do
        before do
          PactBroker.configuration.webhook_retry_schedule = [1, 1, 1]
          allow(subject).to receive(:webhook_executions).and_return([double("execution")])
        end

        its(:number_of_attempts_made) { is_expected.to eq 1 }

        context "when its status is retrying" do
          let(:status) { TriggeredWebhook::STATUS_RETRYING }
          its(:number_of_attempts_remaining) { is_expected.to eq 3  }
        end

        context "when its status is not_run" do
          let(:status) { TriggeredWebhook::STATUS_NOT_RUN }
          its(:number_of_attempts_remaining) { is_expected.to eq 3  }
        end

        context "when its status is success" do
          let(:status) { TriggeredWebhook::STATUS_SUCCESS }
          its(:number_of_attempts_remaining) { is_expected.to eq 0}
        end

        context "when its status is failure" do
          let(:status) { TriggeredWebhook::STATUS_FAILURE }
          its(:number_of_attempts_remaining) { is_expected.to eq 0}
        end
      end

      describe "latest_triggered_webhooks" do
        before do
          td.create_consumer("Foo")
            .create_provider("Bar")
            .create_webhook(uuid: "1")
            .create_consumer_version
            .comment("tw 1")
            .create_pact
            .create_triggered_webhook(status: PactBroker::Webhooks::TriggeredWebhook::STATUS_FAILURE, uuid: "tw1")
            .create_webhook_execution
            .create_consumer_version
            .comment("tw 2")
            .create_pact
            .create_triggered_webhook(status: PactBroker::Webhooks::TriggeredWebhook::STATUS_SUCCESS, uuid: "tw2")
            .create_webhook_execution
            .create_webhook(uuid: "2")
            .create_consumer_version
            .comment("tw 3")
            .create_pact
            .create_triggered_webhook(status: PactBroker::Webhooks::TriggeredWebhook::STATUS_FAILURE, uuid: "tw3")
            .create_webhook_execution
            .create_consumer_version
            .comment("tw 4")
            .create_pact
            .create_triggered_webhook(status: PactBroker::Webhooks::TriggeredWebhook::STATUS_SUCCESS, uuid: "tw4")
            .create_webhook_execution
        end

        subject do
          TriggeredWebhook
            .where(Sequel[:triggered_webhooks][:consumer_id] => td.and_return(:consumer).id)
            .where(Sequel[:triggered_webhooks][:provider_id] => td.and_return(:provider).id)
            .latest_triggered_webhooks
            .all
        end

        it "groups by consumer, provider, webhook and event" do
          expect(subject).to contain_exactly(
            have_attributes(webhook_uuid: "1", uuid: "tw2"),
            have_attributes(webhook_uuid: "2", uuid: "tw4")
          )
        end

        context "when one of the webhooks has been deleted" do
          before do
            PactBroker::Webhooks::Service.delete_by_uuid("2")
          end

          it "does not include the triggered webhook for the deleted webhook" do
            expect(subject).to contain_exactly(
              have_attributes(webhook_uuid: "1", uuid: "tw2")
            )
          end
        end
      end
    end
  end
end
