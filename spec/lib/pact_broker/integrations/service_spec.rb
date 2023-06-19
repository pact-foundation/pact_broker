require "pact_broker/integrations/service"

module PactBroker
  module Integrations
    describe Service do
      describe "#delete" do
        subject { Service.delete("Foo", "Bar") }

        describe "the integration" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
          end

          it "deletes it" do
            expect{ subject }.to change { Integration.count }.by(-1)
          end
        end

        context "with webhook data" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_webhook
              .create_triggered_webhook
              .create_webhook_execution
          end

          it "deletes the webhooks" do
            expect { subject }.to change { PactBroker::Webhooks::Webhook.count }
          end
        end

        context "when the consumer version does not have any other pacts associated with it" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
          end

          it "deletes the consumer version" do
            expect { subject }.to change { PactBroker::Domain::Version.count }
          end
        end

        context "when the consumer version has another pact associated with it" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_provider
              .create_pact
          end

          it "does not delete the consumer version" do
            expect { subject }.to_not change { PactBroker::Domain::Version.count }
          end
        end

        context "when the consumer version has another verification associated with it" do
          # Foo v1 -> Bar (no verification) - deleted
          # Baz v2 -> Foo v1                - not deleted
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer("Baz")
              .create_consumer_version("2")
              .use_provider("Foo")
              .create_pact
              .create_verification(provider_version: "1")
          end

          it "does not delete the consumer version" do
            expect { subject }.to_not change { PactBroker::Domain::Version.count }
          end
        end

        context "when the provider has verifications" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_verification(provider_version: "2")
          end

          it "deletes the verifications" do
            expect { subject }.to change { PactBroker::Domain::Verification.count }
          end
        end

        context "with pact versions" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
          end

          it "deletes the pact versions" do
            expect { subject }.to change { PactBroker::Pacts::PactVersion.count }
          end
        end

        context "when the consumer has other providers" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_provider("Baz")
              .create_consumer_version("2")
              .create_pact
          end

          it "does not delete the consumer" do
            expect { subject }.to_not change { PactBroker::Domain::Pacticipant.where(name: "Foo").count }
          end
        end

        context "when the consumer has other consumers" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer("Baz")
              .create_consumer_version("2")
              .use_provider("Foo")
              .create_pact
          end

          it "does not delete the consumer" do
            expect { subject }.to_not change { PactBroker::Domain::Pacticipant.where(name: "Foo").count }
          end
        end

        context "when the consumer does not have other providers or consumers" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
          end

          it "deletes the consumer" do
            expect { subject }.to change { PactBroker::Domain::Pacticipant.where(name: "Foo").count }
          end
        end

        context "when the provider has other consumers" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer("Baz")
              .create_consumer_version("2")
              .create_pact
          end

          it "does not delete the provider" do
            expect { subject }.to_not change { PactBroker::Domain::Pacticipant.where(name: "Bar").count }
          end
        end

        context "when the provider has other providers" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .use_consumer("Bar")
              .create_consumer_version("2")
              .create_provider("Baz")
              .create_pact
          end

          it "does not delete the provider" do
            expect { subject }.to_not change { PactBroker::Domain::Pacticipant.where(name: "Bar").count }
          end
        end

        context "when the provider does not have other providers or consumers" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
          end

          it "deletes the provider" do
            expect { subject }.to change { PactBroker::Domain::Pacticipant.where(name: "Bar").count }
          end
        end

        context "When a webhook exists between the consumer and another provider" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_provider("Baz")
              .create_webhook
          end

          it "does not delete the consumer" do
            expect { subject }.to_not change { PactBroker::Domain::Pacticipant.where(name: "Foo").count }
          end
        end

        context "When a webhook exists between the provider and another consumer" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer("Baz")
              .create_webhook
          end

          it "does not delete the provider" do
            expect { subject }.to_not change { PactBroker::Domain::Pacticipant.where(name: "Bar").count }
          end
        end

        context "When a pacticipant has labels" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_label("prod")
          end

          it "deletes the label" do
            expect { subject }.to change { PactBroker::Domain::Label.count }
          end

          it "deletes the pacticipant" do
            expect { subject }.to change { PactBroker::Domain::Pacticipant.where(name: "Bar").count }
          end
        end

        context "When a version has tags" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer_version_tag("prod")
          end

          it "deletes the tag" do
            expect { subject }.to change { PactBroker::Domain::Tag.count }
          end

          it "deletes the version" do
            expect { subject }.to change { PactBroker::Domain::Version.count }
          end
        end

        context "when a pacticipant has a pact with itself... I wouldn't have believed it unless I'd seen it..." do
          before do
            td.create_consumer("Foo")
              .use_provider("Foo")
              .create_consumer_version("1")
              .create_pact
          end

          it "doesn't blow up" do
            Service.delete("Foo", "Foo")
          end
        end

        context "when the pacticipants are not found for some bizarre reason (I can't see how this can happen, but it has)" do
          it "raises an error" do
            expect { Service.delete("Foo", "Bar") }.to raise_error(PactBroker::Error, /found/)
          end
        end

        context "when there are deployed versions" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1")
              .create_environment("test")
              .create_deployed_version_for_consumer_version
          end

          it "doesn't blow up" do
            Service.delete("Foo", "Foo")
          end
        end
      end

      describe "delete_all" do
        before do
          td.create_everything_for_an_integration
        end

        it "doesn't blow up" do
          Service.delete_all
          expect(PactBroker::Domain::Pacticipant.count).to be 0
        end
      end
    end
  end
end
