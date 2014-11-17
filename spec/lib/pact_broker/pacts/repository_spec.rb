require 'pact_broker/pacts/repository'
require 'spec/support/provider_state_builder'

module PactBroker
  module Pacts
    describe Repository do

      describe "create" do
        let(:consumer) { Repositories::PacticipantRepository.new.create name: 'Consumer' }
        let(:provider) { Repositories::PacticipantRepository.new.create name: 'Provider' }
        let(:version) { Repositories::VersionRepository.new.create number: '1.2.3', pacticipant_id: consumer.id }
        let(:json_content) { {some: 'json'}.to_json }

        subject { Repository.new.create version_id: version.id, provider_id: provider.id, json_content: json_content}

        it "saves the pact" do
          expect{subject}.to change{ DatabaseModel.count }.by(1)
        end

        it "returns a Pact::Model" do
          expect(subject).to be_instance_of(PactBroker::Domain::Pact)
        end

        it "sets all the Pact::Model attributes" do
          expect(subject.consumer).to eq consumer
          expect(subject.provider).to eq provider
          expect(subject.consumer_version_number).to eq '1.2.3'
          expect(subject.consumer_version.number).to eq '1.2.3'
          expect(subject.json_content).to eq json_content
          expect(subject.created_at).to be_instance_of(DateTime)
          expect(subject.updated_at).to be_instance_of(DateTime)
        end
      end

      describe "update" do

        let(:existing_pact) do
          ProviderStateBuilder.new.create_pact_with_hierarchy "A Consumer", "1.2.3", "A Provider"
        end

        before do
          ::DB::PACT_BROKER_DB[:pacts]
            .where(id: existing_pact.id)
            .update(
              created_at: created_at,
              updated_at: updated_at)
          ::DB::PACT_BROKER_DB[:pact_version_contents]
              .update(
                created_at: created_at,
                updated_at: updated_at)
        end

        let(:created_at) { DateTime.new(2014, 3, 2) }
        let(:updated_at) { DateTime.new(2014, 3, 4) }

        let(:json_content) { {some: 'json'}.to_json }

        subject { Repository.new.update existing_pact.id, json_content: json_content }

        context "when the attributes have changed" do

          it "updates the existing content" do
            expect(subject.json_content).to eq json_content
          end

          it "updates the updated_at timestamp" do
            expect(subject.updated_at).to_not eq updated_at
          end

          it "does not update the created_at timestamp" do
            expect(subject.created_at).to eq created_at
          end

        end

        context "when the attributes have not changed" do
          before do

            ::DB::PACT_BROKER_DB[:pact_version_contents]
              .update(
                content: json_content)
          end

          it "does not update the updated_at timestamp" do
            expect(subject.updated_at).to eq updated_at
          end

          it "does not update the created_at timestamp" do
            expect(subject.created_at).to eq created_at
          end

        end

      end

      describe "#find_all_pacts_between" do
        let(:consumer_name) { 'Consumer' }
        let(:provider_name) { 'Provider' }

        before do
          ProviderStateBuilder.new
            .create_consumer(consumer_name)
            .create_consumer_version("1.2.3")
            .create_provider(provider_name)
            .create_pact
            .create_consumer_version("2.3.4")
            .create_consumer_version_tag("prod")
            .create_consumer_version_tag("branch")
            .create_pact
            .create_provider("Another Provider")
            .create_pact
        end

        subject { Repository.new.find_all_pacts_between consumer_name, :and => provider_name }

        it "returns the pacts between the specified consumer and provider" do
          expect(subject.size).to eq 2
          expect(subject.first.consumer.name).to eq consumer_name
          expect(subject.first.provider.name).to eq provider_name
          expect(subject.first.consumer_version.number).to eq "2.3.4"
          expect(subject.first.consumer_version.tags.first.name).to eq "prod"
          expect(subject.first.consumer_version.tags.last.name).to eq "branch"
        end

      end

      describe "find_pact" do
        before do
          ProviderStateBuilder.new
            .create_consumer("Consumer")
            .create_consumer_version("1.2.2")
            .create_provider("Provider")
            .create_pact
            .create_consumer_version("1.2.4")
            .create_consumer_version_tag("prod")
            .create_pact
            .create_consumer_version("1.2.6")
            .create_pact
            .create_provider("Another Provider")
            .create_consumer_version("1.2.5")
            .create_pact
        end

        subject  { Repository.new.find_pact "Consumer", "1.2.4", "Provider" }

        it "finds the pact with the given version" do
          expect(subject.consumer.name).to eq "Consumer"
          expect(subject.provider.name).to eq "Provider"
          expect(subject.consumer_version_number).to eq "1.2.4"
          expect(subject.consumer_version.number).to eq "1.2.4"
          expect(subject.consumer_version.tags.first.name).to eq "prod"
          expect(subject.json_content).to_not be_nil
        end
      end

      describe "find_previous_pact" do
        before do
          ProviderStateBuilder.new
            .create_consumer("Consumer")
            .create_consumer_version("1.2.2")
            .create_provider("Provider")
            .create_pact
            .create_consumer_version("1.2.4")
            .create_pact
            .create_consumer_version("1.2.6")
            .create_pact
            .create_provider("Another Provider")
            .create_consumer_version("1.2.5")
            .create_pact
        end

        let(:pact) { Repository.new.find_latest_pact "Consumer", "Provider"  }

        subject  { Repository.new.find_previous_pact pact }

        it "finds the previous pact" do
          expect(subject.consumer_version_number).to eq "1.2.4"
          expect(subject.consumer_version.number).to eq "1.2.4"
        end
      end

      describe "find_latest_pact" do

        context "with a tag" do
          context "when a version with a pact exists with the given tag" do
            before do
              ProviderStateBuilder.new
                .create_consumer("Consumer")
                .create_consumer_version("2.3.4")
                .create_provider("Provider")
                .create_pact
                .create_consumer_version("1.2.3")
                .create_consumer_version_tag("prod")
                .create_pact
            end

            let(:latest_prod_pact) { Repository.new.find_latest_pact("Consumer", "Provider", "prod") }

            it "returns the pact for the latest tagged version" do
              expect(latest_prod_pact.consumer_version.number).to eq("1.2.3")
            end

            it "has JSON content" do
              expect(latest_prod_pact.json_content).to_not be nil
            end

            it "has timestamps" do
              expect(latest_prod_pact.created_at).to be_instance_of(DateTime)
              expect(latest_prod_pact.updated_at).to be_instance_of(DateTime)
            end
          end

        end
      end

      describe "find_latest_pacts" do
        before do
          ProviderStateBuilder.new
            .create_condor
            .create_condor_version('1.3.0')
            .create_pricing_service
            .create_condor_pricing_service_pact
            .create_condor_version('1.4.0')
            .create_condor_pricing_service_pact
            .create_contract_email_service
            .create_contract_email_service_version('2.6.0')
            .create_contract_proposal_service
            .create_ces_cps_pact
            .create_contract_email_service_version('2.7.0')
            .create_ces_cps_pact
            .create_contract_email_service_version('2.8.0') # Create a version without a pact, it shouldn't be used
        end

        it "finds the latest pact for each consumer/provider pair" do
          pacts = Repository.new.find_latest_pacts

          expect(pacts[0].consumer_version.pacticipant.name).to eq("Condor")
          expect(pacts[0].consumer.name).to eq("Condor")
          expect(pacts[0].consumer.id).to_not be nil
          expect(pacts[0].provider.name).to eq("Pricing Service")
          expect(pacts[0].provider.id).to_not be nil
          expect(pacts[0].consumer_version.number).to eq("1.4.0")

          expect(pacts[1].consumer_version.pacticipant.name).to eq("Contract Email Service")
          expect(pacts[1].consumer.name).to eq("Contract Email Service")
          expect(pacts[1].provider.name).to eq("Contract Proposal Service")
          expect(pacts[1].consumer_version.number).to eq("2.7.0")
        end

        it "includes the timestamps - need to update view" do
          pacts = Repository.new.find_latest_pacts

          expect(pacts[0].updated_at).to be_instance_of DateTime
          expect(pacts[0].created_at).to be_instance_of DateTime
        end
      end
    end
  end
end
