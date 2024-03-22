require "pact_broker/integrations/integration"

module PactBroker
  module Integrations
    describe Integration do
      describe "filter" do
        before do
          td.create_consumer("Foo")
            .create_provider("Bar")
            .create_integration
            .create_consumer("Cat")
            .create_provider("Dog")
            .create_integration
            .create_consumer("Y")
            .create_provider("Z")
            .create_integration
        end

        subject { Integration.select_all_qualified.filter_by_pacticipant(query_string).all }

        context "with a filter matching the consumer" do
          let(:query_string) { "oo" }

          it { is_expected.to contain_exactly(have_attributes(consumer_name: "Foo", provider_name: "Bar")) }
        end

        context "with a filter matching the provider" do
          let(:query_string) { "ar" }

          it { is_expected.to contain_exactly(have_attributes(consumer_name: "Foo", provider_name: "Bar")) }
        end

        context "with a filter matching both consumer and provider" do
          let(:query_string) { "o" }

          it "returns the matching integrations" do
            expect(subject).to contain_exactly(
              have_attributes(consumer_name: "Foo", provider_name: "Bar"),
              have_attributes(consumer_name: "Cat", provider_name: "Dog")
            )
          end
        end
      end

      describe "relationships" do
        before do
          td.set_now(DateTime.new(2018, 1, 7))
            .create_pact_with_hierarchy("Zoo", "1", "Yab")
            .set_now(DateTime.new(2019, 1, 1))
            .create_pact_with_hierarchy("Foo", "1", "Bar")
            .set_now(DateTime.new(2019, 1, 2))
            .create_consumer_version("2")
            .create_pact
            .set_now(DateTime.new(2019, 1, 3))
            .create_verification(provider_version: "3")
            .set_now(DateTime.new(2019, 1, 4))
            .create_verification(provider_version: "4", number: 2)
        end

        it "has a relationship to the latest pact (eager)" do
          integrations = Integration.eager(:latest_pact).order(Sequel.desc(:id)).all
          expect(integrations.first.associations[:latest_pact].consumer_version.number).to eq "2"
          expect(integrations.last.associations[:latest_pact].consumer_version.number).to eq "1"
        end

        it "has a relationship to the latest pact (lazy)" do
          integrations = Integration.order(Sequel.desc(:id)).all
          expect(integrations.first.latest_pact.consumer_version.number).to eq "2"
          expect(integrations.last.latest_pact.consumer_version.number).to eq "1"
        end

        it "has a relationship to the latest verification via the latest pact" do
          integration = Integration.eager(:latest_pact).order(Sequel.desc(:id)).all.first
          expect(integration.associations[:latest_pact].latest_verification.provider_version_number).to eq "4"
        end

        it "has a verification status" do
          expect(Integration.first.verification_status_for_latest_pact).to be_instance_of(PactBroker::Verifications::PseudoBranchStatus)
        end

        it "has a latest verification - this may not be the same as the latest verification for the latest pact" do
          integration = Integration.eager(:latest_verification).order(Sequel.desc(:id)).all.first
          expect(integration.associations[:latest_verification].provider_version_number).to eq "4"
        end

        describe "latest_pact_or_verification_publication_date" do
          let(:first_integration) { Integration.order(:id).last }

          context "when the last publication is a verification" do
            it "returns the verification execution date" do
              expect(first_integration.latest_pact_or_verification_publication_date.to_datetime).to eq first_integration.latest_verification_publication_date.to_datetime
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
              expect(first_integration.latest_pact_or_verification_publication_date.to_datetime).to eq date
            end
          end

          context "when there is no pact or verification" do
            before do
              td.create_consumer("orphan-consumer")
                .create_provider("orphan-provider")
                .create_integration
            end

            it "returns nil" do
              expect(Integration.last.latest_pact_or_verification_publication_date).to be nil
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
            .create_webhook
            .create_triggered_webhook(uuid: "1")
            .create_webhook_execution
            .create_triggered_webhook(uuid: "2")
            .create_webhook_execution
            .create_consumer("NotFoo")
            .create_provider("NotBar")
            .create_consumer_version
            .create_pact
            .create_webhook
            .create_triggered_webhook(uuid: "3")
            .create_webhook_execution
            .create_triggered_webhook(uuid: "4")
            .create_webhook_execution
        end

        context "lazy loading" do
          it "returns a list of triggered webhooks" do
            integrations = Integration.order(Sequel.desc(:id)).all
            expect(integrations.first.latest_triggered_webhooks.count).to eq 1
          end
        end

        context "eager loading" do
          it "returns a list of triggered webhooks" do
            integrations = Integration.eager(:latest_triggered_webhooks).order(Sequel.desc(:id)).all
            expect(integrations.first.associations[:latest_triggered_webhooks].count).to eq 1
          end
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
          integrations = Integration.eager(:webhooks).order(Sequel.desc(:id)).all
          expect(integrations.first.webhooks.count).to eq 3
        end
      end
    end
  end
end
