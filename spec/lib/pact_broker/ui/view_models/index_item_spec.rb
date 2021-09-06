require "spec_helper"
require "pact_broker/ui/view_models/index_item"
require "pact_broker/domain/index_item"

module PactBroker
  module UI
    module ViewDomain
      describe IndexItem do

        let(:consumer) { instance_double("PactBroker::Domain::Pacticipant", name: "Consumer Name") }
        let(:provider) { instance_double("PactBroker::Domain::Pacticipant", name: "Provider Name") }
        let(:consumer_version) { instance_double("PactBroker::Domain::Version") }

        let(:latest_pact) { instance_double("PactBroker::Domain::Pact", consumer_version_number: "1.2.3") }
        let(:latest_verification) { instance_double("PactBroker::Domain::Verification") }
        let(:domain_relationship) { PactBroker::Domain::IndexItem.new(consumer, provider, consumer_version, latest_pact, latest, latest_verification, [], [], tags, latest_verification_latest_tags)}
        let(:tags) { [] }
        let(:verification_tag_1) { instance_double("PactBroker::Tags::TagWithLatestFlag", name: "dev") }
        let(:verification_tag_2) { instance_double("PactBroker::Tags::TagWithLatestFlag", name: "prod") }
        let(:latest_verification_latest_tags) { [verification_tag_1, verification_tag_2]  }
        let(:latest) { true }

        subject { IndexItem.new(domain_relationship) }

        its(:consumer_name) { should eq "Consumer Name"}
        its(:provider_name) { should eq "Provider Name"}
        its(:latest_pact_url) { should eq "/pacts/provider/Provider%20Name/consumer/Consumer%20Name/latest" }
        its(:pact_url) { should eq "/pacts/provider/Provider%20Name/consumer/Consumer%20Name/version/1.2.3" }
        its(:pact_matrix_url) { should eq "/matrix/provider/Provider%20Name/consumer/Consumer%20Name" }
        its(:consumer_group_url) { should eq "/groups/Consumer%20Name" }
        its(:provider_group_url) { should eq "/groups/Provider%20Name" }

        describe "pseudo_branch_verification_status" do
          let(:domain_relationship) do
            instance_double("PactBroker::Domain::IndexItem",
              pseudo_branch_verification_status: pseudo_branch_verification_status,
              provider_name: "Foo",
              latest_verification_provider_version_number: "4.5.6")
          end
          let(:ever_verified) { true }
          let(:pact_changed) { false }
          let(:success) { true }

          subject { IndexItem.new(domain_relationship) }

          context "when the pact has never been verified" do
            let(:pseudo_branch_verification_status) { :never }
            its(:pseudo_branch_verification_status) { is_expected.to eq "" }
            its(:warning?) { is_expected.to be false }
            its(:verification_tooltip) { is_expected.to eq nil }
          end

          context "when the pact has changed since the last successful verification" do
            let(:pseudo_branch_verification_status) { :stale }
            its(:pseudo_branch_verification_status) { is_expected.to eq "warning" }
            its(:warning?) { is_expected.to be true }
            its(:verification_tooltip) { is_expected.to eq "Pact has changed since last successful verification by Foo (4.5.6)" }
          end

          context "when the pact has not changed since the last successful verification" do
            let(:pseudo_branch_verification_status) { :success }
            its(:pseudo_branch_verification_status) { is_expected.to eq "success" }
            its(:warning?) { is_expected.to be false }
            its(:verification_tooltip) { is_expected.to eq "Successfully verified by Foo (4.5.6)" }
          end

          context "when the pact verification failed" do
            let(:pseudo_branch_verification_status) { :failed }
            its(:pseudo_branch_verification_status) { is_expected.to eq "danger" }
            its(:warning?) { is_expected.to be false }
            its(:verification_tooltip) { is_expected.to eq "Verification by Foo (4.5.6) failed" }
          end
        end

        describe "webhooks" do
          let(:domain_relationship) do
            instance_double("PactBroker::Domain::IndexItem",
              webhook_status: webhook_status,
              last_webhook_execution_date: DateTime.now - 1,
              latest_pact: double("pact", consumer: consumer, provider: provider),
              latest?: true
            )
          end
          let(:webhook_status) { :none }

          subject { IndexItem.new(domain_relationship) }

          context "when the webhooks_status is :none" do
            its(:webhook_label) { is_expected.to eq "Create" }
            its(:webhook_status) { is_expected.to eq "" }
            its(:webhook_url) { is_expected.to end_with "/webhooks/provider/Provider%20Name/consumer/Consumer%20Name"}
          end

          context "when the webhooks_status is :success" do
            let(:webhook_status) { :success }
            its(:webhook_label) { is_expected.to eq "1 day ago" }
            its(:webhook_status) { is_expected.to eq "success" }
            its(:webhook_url) { is_expected.to end_with "/pacts/provider/Provider%20Name/consumer/Consumer%20Name/webhooks/status"}
          end

          context "when the webhooks_status is :failure" do
            let(:webhook_status) { :failure }
            its(:webhook_label) { is_expected.to eq "1 day ago" }
            its(:webhook_status) { is_expected.to eq "danger" }
          end

          context "when the webhooks_status is :not_run" do
            let(:webhook_status) { :not_run }
            its(:webhook_label) { is_expected.to eq "Not run" }
            its(:webhook_status) { is_expected.to eq "" }
          end

          context "when the webhooks_status is :retrying" do
            let(:webhook_status) { :retrying }
            its(:webhook_label) { is_expected.to eq "Retrying" }
            its(:webhook_status) { is_expected.to eq "warning" }
          end
        end

        describe "latest?" do
          context "when the pact is the overall latest" do
            its(:latest?) { is_expected.to be true }
          end

          context "when the pact is not the latest" do
            let(:latest) { false }
            its(:latest?) { is_expected.to be false }
          end
        end

        describe "consumer_version_latest_tag_names" do
          let(:tags) { ["master", "prod"] }
          its(:consumer_version_latest_tag_names) { is_expected.to eq ["master", "prod"] }
        end

        describe "provider_version_latest_tag_names" do
          its(:provider_version_latest_tag_names) { is_expected.to eq ["dev", "prod"] }
        end

        describe "tagged_pacts" do
          let(:tags) { ["master", "prod"] }
          its(:tagged_pacts) do
            is_expected.to eq([
              { tag: "master", deletionUrl: "/pacts/provider/Provider%20Name/consumer/Consumer%20Name/tag/master" }.to_json,
              { tag: "prod", deletionUrl: "/pacts/provider/Provider%20Name/consumer/Consumer%20Name/tag/prod" }.to_json
            ])
          end
        end

        describe "<=>" do

          let(:relationship_model_4) { double("PactBroker::Domain::IndexItem", consumer_name: "A", provider_name: "X") }
          let(:relationship_model_2) { double("PactBroker::Domain::IndexItem", consumer_name: "a", provider_name: "y") }
          let(:relationship_model_3) { double("PactBroker::Domain::IndexItem", consumer_name: "A", provider_name: "Z") }
          let(:relationship_model_1) { double("PactBroker::Domain::IndexItem", consumer_name: "C", provider_name: "A") }

          let(:relationship_models) { [relationship_model_1, relationship_model_3, relationship_model_4, relationship_model_2] }
          let(:ordered_view_models) { [relationship_model_4, relationship_model_2, relationship_model_3, relationship_model_1] }

          let(:relationship_view_models) { relationship_models.collect{ |r| IndexItem.new(r)} }

          it "sorts by consumer name then provider name" do
            expect(relationship_view_models.sort.collect{ |r| [r.consumer_name, r.provider_name]})
              .to eq([["A", "X"],["a","y"],["A","Z"],["C", "A"]])
          end
        end
      end
    end
  end
end
