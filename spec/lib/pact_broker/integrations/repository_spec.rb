require "pact_broker/integrations/repository"
require "timecop"

module PactBroker
  module Integrations
    describe Repository do
      describe "find" do
        before do
          Timecop.freeze(Date.today - 5) do
            td.publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "1")
          end

          Timecop.freeze(Date.today - 4) do
            td.create_verification(provider_version: "2")
          end

          Timecop.freeze(Date.today - 3) do
            td.publish_pact(consumer_name: "Apple", provider_name: "Pear", consumer_version_number: "1")
          end

          Timecop.freeze(Date.today - 2) do
            td.create_verification(provider_version: "2")
          end

          # No contract data date
          td.create_consumer("Dog")
            .create_provider("Cat")
            .create_integration
        end

        subject { Repository.new.find }

        it "it orders by most recent event" do
          expect(subject[0]).to have_attributes(consumer_name: "Apple")
          expect(subject[1]).to have_attributes(consumer_name: "Foo")
          expect(subject[2]).to have_attributes(consumer_name: "Dog")
        end
      end

      describe "#set_contract_data_updated_at" do
        before do
          # A -> B
          # Foo -> Bar
          td.create_consumer("A")
            .create_provider("B")
            .create_integration
            .create_consumer("Foo")
            .create_provider("Bar")
            .create_integration
        end

        let(:then) { Date.today - 20 }
        let(:now) { DateTime.new(2010, 11, 1, 1, 1, 1) }
        let(:foo) { td.and_return(:consumer) }
        let(:bar) { td.and_return(:provider) }

        subject do
          Timecop.freeze(now) do
            Repository.new.set_contract_data_updated_at(foo, bar)
          end
        end

        it "updates the contract_data_updated_at to now" do
          subject
          expect(Integration.last.contract_data_updated_at).to be_date_time(now)
        end

        it "does not update the other integrations" do
          expect { subject }.to_not change { Integration.first.contract_data_updated_at }
        end

        context "with the consumer is nil (eg. when a provider contract is published in Pactflow)" do
          before do
            # A -> B
            # Foo -> Bar
            # A -> Bar
            td.use_consumer("A")
              .use_provider("Bar")
              .create_integration
          end

          subject do
            Timecop.freeze(now) do
              Repository.new.set_contract_data_updated_at(nil, bar)
            end
          end

          it "updates all the integrations for the provider" do
            subject
            integrations = Integration.select_all_qualified.including_pacticipant_id(bar.id)
            expect(integrations.first.contract_data_updated_at).to be_date_time(now)
            expect(integrations.last.contract_data_updated_at).to be_date_time(now)
          end
        end
      end
    end
  end
end
