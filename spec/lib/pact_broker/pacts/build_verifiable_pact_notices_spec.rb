require "pact_broker/pacts/build_verifiable_pact_notices"

module PactBroker
  module Pacts
    describe BuildVerifiablePactNotices do
      before do
        allow(VerifiablePactMessages).to receive(:new).and_return(verifiable_pact_messages)
      end

      let(:verifiable_pact_messages) do
        instance_double(VerifiablePactMessages,
          inclusion_reason: "the inclusion reason",
          pending_reason: "pending reason",
          verification_success_true_published_false: "verification_success_true_published_false",
          verification_success_false_published_false: "verification_success_false_published_false",
          verification_success_true_published_true: "verification_success_true_published_true",
          verification_success_false_published_true: "verification_success_false_published_true"
        )
      end

      let(:options) { {} }
      let(:pact_url) { "http://pact" }
      let(:verifiable_pact) { instance_double("PactBroker::Pacts::VerifiablePact") }

      subject { BuildVerifiablePactNotices.call(verifiable_pact, pact_url, options) }

      context "when include_pending_status is true" do
        let(:expected_notices) do
          [
            {
              :when => "before_verification",
              :text => "the inclusion reason"
            },{
              :when => "before_verification",
              :text => "pending reason"
            },{
              :when => "after_verification:success_true_published_false",
              :text => "verification_success_true_published_false"
            },{
              :when => "after_verification:success_false_published_false",
              :text => "verification_success_false_published_false"
            },{
              :when => "after_verification:success_true_published_true",
              :text => "verification_success_true_published_true"
            },{
              :when => "after_verification:success_false_published_true",
              :text => "verification_success_false_published_true"
            }
          ]
        end

        let(:options) { { include_pending_status: true } }

        it "it returns a list of notices with information about the pending status" do
          expect(subject).to eq expected_notices
        end
      end

      context "when include_pending_status is not true" do
        let(:expected_notices) do
          [
            {
              :when => "before_verification",
              :text => "the inclusion reason"
            }
          ]
        end

        it "it returns a list of notices without information about the pending status" do
          expect(subject).to eq expected_notices
        end
      end
    end
  end
end
