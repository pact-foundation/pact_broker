require 'pact_broker/integrations/integration'

module PactBroker
  module Integrations
    describe Integration do
      describe "relationships" do
        before do
          td.set_now(DateTime.new(2019, 1, 1))
            .create_pact_with_hierarchy("Foo", "1", "Bar")
            .set_now(DateTime.new(2019, 1, 2))
            .create_consumer_version("2")
            .create_pact
            .set_now(DateTime.new(2019, 1, 3))
            .create_verification(provider_version: "3")
            .set_now(DateTime.new(2019, 1, 4))
            .create_verification(provider_version: "4", number: 2)
        end

        it "has a relationship to the latest pact" do
          integration = Integration.eager(:latest_pact).all.first
          expect(integration.latest_pact.consumer_version_number).to eq "2"
        end

        it "has a relationship to the latest verification via the latest pact" do
          integration = Integration.eager(latest_pact: :latest_verification).all.first
          expect(integration.latest_pact.latest_verification.provider_version_number).to eq "4"
        end

        it "has a verification status" do
          expect(Integration.first.verification_status_for_latest_pact).to be_instance_of(PactBroker::Verifications::PseudoBranchStatus)
        end

        it "has a latest verification - this may not be the same as the latest verification for the latest pact" do
          integration = Integration.eager(:latest_verification).all.first
          expect(integration.latest_verification.provider_version_number).to eq "4"
        end

        describe "latest_pact_or_verification_publication_date" do
          context "when the last publication is a verification" do
            it "returns the verification execution date" do
              expect(Integration.first.latest_pact_or_verification_publication_date.to_datetime).to eq Integration.first.latest_verification_publication_date
            end
          end

          context "when the last publication is a pact" do
            before do
              td.set_now(DateTime.new(2019, 1, 5))
                .create_consumer_version("3")
                .create_pact
            end

            it "returns the pact publication date" do
              date = td.in_utc { DateTime.new(2019, 1, 5) }
              expect(Integration.first.latest_pact_or_verification_publication_date.to_datetime).to eq date
            end
          end
        end
      end

      describe "latest_triggered_webhooks" do
        before do
          td.create_consumer("Foo")
            .create_provider("Bar")
            .create_consumer_version
            .create_pact
            .create_global_webhook
            .create_triggered_webhook
            .create_webhook_execution
        end

        it "returns a list of triggered webhooks" do
          integrations = Integration.eager(:latest_triggered_webhooks).all
          expect(integrations.first.latest_triggered_webhooks.count).to eq 1
        end
      end

      describe "webhooks" do
        before do
          td.create_consumer("Foo")
            .create_provider("Bar")
            .create_consumer_version
            .create_pact
            .create_global_webhook
            .create_consumer_webhook
            .create_provider_webhook
            .create_provider("Wiffle")
            .create_provider_webhook
        end

        it "returns all the webhooks" do
          integrations = Integration.eager(:webhooks).all
          expect(integrations.first.webhooks.count).to eq 3
        end
      end
    end
  end
end
