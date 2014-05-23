require 'spec_helper'
require 'spec/support/provider_state_builder'

module PactBroker
  module Repositories
    describe PactRepository do

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

            let(:latest_prod_pact) { PactRepository.new.find_latest_pact("Consumer", "Provider", "prod") }

            it "returns the pact for the latest tagged version" do
              expect(latest_prod_pact.consumer_version.number).to eq("1.2.3")
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
          pacts = PactRepository.new.find_latest_pacts

          expect(pacts[0].consumer_version.pacticipant.name).to eq("Condor")
          expect(pacts[0].consumer.name).to eq("Condor")
          expect(pacts[0].provider.name).to eq("Pricing Service")
          expect(pacts[0].consumer_version.number).to eq("1.4.0")

          expect(pacts[1].consumer_version.pacticipant.name).to eq("Contract Email Service")
          expect(pacts[1].consumer.name).to eq("Contract Email Service")
          expect(pacts[1].provider.name).to eq("Contract Proposal Service")
          expect(pacts[1].consumer_version.number).to eq("2.7.0")
        end
      end
    end
  end
end
