require "pact_broker/integrations/repository"
require "timecop"

module PactBroker
  module Integrations
    describe Repository do
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
          expect { subject }.to change { Integration.last.contract_data_updated_at }.from(nil).to(now)
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
