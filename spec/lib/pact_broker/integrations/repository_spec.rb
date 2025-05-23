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

          # Nil contract data date
          td.create_consumer("Dog")
            .create_provider("Cat")
            .create_integration
          Integration.order(:id).last.update(contract_data_updated_at: nil)
        end

        let(:options) do
          {
            :query_string => query_string
          }
        end
        let(:query_string) { nil }

        subject { Repository.new.find(options) }

        it "it orders by most recent event" do
          expect(subject[0]).to have_attributes(consumer_name: "Apple")
          expect(subject[1]).to have_attributes(consumer_name: "Foo")
          expect(subject[2]).to have_attributes(consumer_name: "Dog")
        end

        context "when method called with filter_options" do
          context "when query_string is like pacticipant name" do
            let(:query_string) { "oo" }

            it "returns the matching integration" do
              expect(subject).to contain_exactly(have_attributes(consumer_name: "Foo", provider_name: "Bar"))
            end
          end

          context "when query_string is not matching pacticipant name" do
            let(:query_string) { "x" }

            it "returns empty array" do
              expect(subject.length).to eq 0
            end
          end
        end
      end

      describe "#create_for_pacts" do
        before do
          Timecop.freeze(Date.today - 5) do
            td.create_consumer("A")
              .create_provider("B")
              .create_integration
              .create_pacticipant("C")
              .create_pacticipant("D")
          end
        end

        let(:objects_with_consumer_and_provider) do
          [
            double("i1", consumer: td.find_pacticipant("A"), provider: td.find_pacticipant("B")),
            double("i2", consumer: td.find_pacticipant("C"), provider: td.find_pacticipant("D"))
          ]
        end

        subject { Repository.new.create_for_pacts(objects_with_consumer_and_provider) }

        it "inserts any missing integrations" do
          now = Time.utc(2024)
          Timecop.freeze(now) do
            subject
          end

          integrations = Integration.eager(:consumer, :provider).order(:id).all
          expect(integrations).to contain_exactly(
            have_attributes(consumer_name: "A", provider_name: "B"),
            have_attributes(consumer_name: "C", provider_name: "D")
          )
          expect(integrations.last.created_at).to be_date_time(now)
          expect(integrations.last.contract_data_updated_at).to be_date_time(now)
        end

        it "does not change the created_at or contract_data_updated_at of the existing integrations" do
          expect { subject }.to_not change { Integration.order(:id).select(:created_at, :contract_data_updated_at).first.created_at }
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
          expect(Integration.order(:id).last.contract_data_updated_at).to be_date_time(now)
        end

        it "does not update the other integrations" do
          expect { subject }.to_not change { Integration.order(:id).first.contract_data_updated_at }
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

      describe "#set_contract_data_updated_at_for_multiple_integrations" do
        before do
          Timecop.freeze(date_1) do
            td.create_consumer("Foo1")
              .create_provider("Bar1")
              .create_integration
              .create_consumer("Foo2")
              .create_provider("Bar2")
              .create_integration
              .create_consumer("Foo3")
              .create_provider("Bar3")
              .create_integration
          end
        end

        let(:date_1) { Time.new(2023, 1, 1).utc.to_datetime }
        let(:date_2) { Time.new(2023, 1, 2).utc.to_datetime }

        let(:objects_with_consumer_and_provider) do
          [
            OpenStruct.new(consumer: td.find_pacticipant("Foo1"), provider: td.find_pacticipant("Bar1")),
            OpenStruct.new(consumer: td.find_pacticipant("Foo2"), provider: td.find_pacticipant("Bar2"))
          ]
        end

        subject do
          Timecop.freeze(date_2) do
            Repository.new.set_contract_data_updated_at_for_multiple_integrations(objects_with_consumer_and_provider)
          end
        end

        it "sets the contract_data_updated_at of the specified integrations" do
          subject
          integrations = Integration.order(:id).all
          expect(integrations[0].contract_data_updated_at).to be_date_time(date_2)
          expect(integrations[1].contract_data_updated_at).to be_date_time(date_2)
          expect(integrations[2].contract_data_updated_at).to be_date_time(date_1)
        end
      end
    end
  end
end
