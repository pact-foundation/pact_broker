require 'spec_helper'
require 'pact_broker/pacts/service'
require 'pact_broker/pacts/pact_params'


module PactBroker

  module Pacts
    describe Service do

      let(:td) { TestDataBuilder.new }

      describe "find_distinct_pacts_between" do
        let(:pact_1) { double('pact 1', json_content: 'content 1')}
        let(:pact_2) { double('pact 2', json_content: 'content 2')}
        let(:pact_3) { double('pact 3', json_content: 'content 2')}
        let(:pact_4) { double('pact 4', json_content: 'content 3')}

        let(:all_pacts) { [pact_4, pact_3, pact_2, pact_1]}

        before do
          allow_any_instance_of(Pacts::Repository).to receive(:find_all_pact_versions_between).and_return(all_pacts)
        end

        subject { Service.find_distinct_pacts_between 'consumer', :and => 'provider' }

        it "returns the distinct pacts" do
          expect(subject).to eq [pact_4, pact_2, pact_1]
        end

      end

      describe "#pact_has_changed_since_previous_version?" do
        let(:pact) { instance_double(PactBroker::Domain::Pact, interactions: [{ description: 'some' }], metadata: { pactSpecificationVersion: "1.0.0" })}

        before do
          allow_any_instance_of(Pacts::Repository).to receive(:find_previous_pact).and_return(previous_pact)
        end

        subject { Service.pact_has_changed_since_previous_version? pact }

        context "when a previous pact is found" do
          let(:interaction) { { description: 'some' } }
          let(:metadata) { { pactSpecificationVersion: "1.0.0" } }
          let(:previous_pact) { instance_double(PactBroker::Domain::Pact, interactions: [interaction], metadata: metadata)}

          context "when the content hash are the same" do
            it "returns false" do
              expect(subject).to be_falsey
            end
          end

          context "when interactions different" do
            let(:interaction) { { description: 'diff' } }
            it "returns truthy" do
              expect(subject).to be_truthy
            end
          end

          context "when pactSpecificationVersions are different" do
            let(:metadata) { { pactSpecificationVersion: "0.0.1" } }
            it "returns truthy" do
              expect(subject).to be_truthy
            end
          end
        end

        context "when a previous pact is not found" do
          let(:previous_pact) { nil }
          it "returns true" do
            expect(subject).to be_truthy
          end
        end
      end

      describe "delete" do
        before do
          td.create_pact_with_hierarchy
            .create_webhook
            .create_triggered_webhook
            .create_webhook_execution
            .create_deprecated_webhook_execution
            .revise_pact
        end

        let(:params) do
          {
            consumer_name: td.consumer.name,
            provider_name: td.provider.name,
            consumer_version_number: td.consumer_version.number
          }
        end

        subject { Service.delete PactParams.new(PactBroker::Pacts::PactParams.new(params)) }

        it "deletes the pact" do
          expect { subject }.to change {
            Pacts::PactPublication.where(id: td.pact.id ).count
          }.by(-1)
        end
      end
    end
  end
end
