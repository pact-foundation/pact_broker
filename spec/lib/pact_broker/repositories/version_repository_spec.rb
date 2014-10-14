require 'spec_helper'
require 'pact_broker/repositories/version_repository'

module PactBroker
  module Repositories
    describe VersionRepository do

      let(:pacticipant_name) { "test_pacticipant" }
      let(:version_number) { "1.2.3" }

      describe "#create" do
        context "when a previous version exists" do

          let!(:existing_order) do
            ProviderStateBuilder.new.create_version_with_hierarchy pacticipant_name, version_number
          end

          subject { VersionRepository.new.create pacticipant_id: existing_order.pacticipant_id, number: "1.2.4" }

          it "sets the order to the previous version's order plus one" do
            expect(subject.order).to eq existing_order.order + 1
          end

        end
      end

      describe "#find_by_pacticipant_name_and_number" do


        subject { described_class.new.find_by_pacticipant_name_and_number pacticipant_name, version_number }

        context "when the version exists" do
          before do
            ProviderStateBuilder.new.create_version_with_hierarchy "other_pacticipant", version_number
            ProviderStateBuilder.new.create_version_with_hierarchy pacticipant_name, version_number
          end

          it "returns the version" do
            expect(subject.number).to eq version_number
            expect(subject.pacticipant.name).to eq pacticipant_name
            expect(subject.order).to eq 0
          end
        end

        context "when the version doesn't exist" do
          it "returns nil" do
            expect(subject).to be_nil
          end
        end

      end


    end
  end
end