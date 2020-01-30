require 'pact_broker/api/decorators/verifiable_pact_decorator'

module PactBroker
  module Api
    module Decorators
      describe VerifiablePactDecorator do
        before do
          allow_any_instance_of(PactBroker::Api::PactBrokerUrls).to receive(:pact_version_url).and_return('/pact-version-url')
          allow_any_instance_of(PactBroker::Pacts::VerifiablePactMessages).to receive(:inclusion_reason).and_return("the inclusion reason")
          allow_any_instance_of(PactBroker::Pacts::VerifiablePactMessages).to receive(:pending_reason).and_return(pending_reason)
          allow_any_instance_of(PactBroker::Pacts::VerifiablePactMessages).to receive(:verification_success_true_published_false).and_return('verification_success_true_published_false')
          allow_any_instance_of(PactBroker::Pacts::VerifiablePactMessages).to receive(:verification_success_false_published_false).and_return('verification_success_false_published_false')
          allow_any_instance_of(PactBroker::Pacts::VerifiablePactMessages).to receive(:verification_success_true_published_true).and_return('verification_success_true_published_true')
          allow_any_instance_of(PactBroker::Pacts::VerifiablePactMessages).to receive(:verification_success_false_published_true).and_return('verification_success_false_published_true')
        end
        let(:pending_reason) { "the pending reason" }
        let(:expected_hash) do
          {
            "verificationProperties" => {
              "pending" => true,
              "notices" => [
                {
                  "when" => "before_verification",
                  "text" => "the inclusion reason"
                },{
                  "when" => "before_verification",
                  "text" => pending_reason
                },{
                  "when" => "after_verification:success_true_published_false",
                  "text" => "verification_success_true_published_false"
                },{
                  "when" => "after_verification:success_false_published_false",
                  "text" => "verification_success_false_published_false"
                },{
                  "when" => "after_verification:success_true_published_true",
                  "text" => "verification_success_true_published_true"
                },{
                  "when" => "after_verification:success_false_published_true",
                  "text" => "verification_success_false_published_true"
                }
              ]
            },
            "_links" => {
              "self" => {
                "href" => "/pact-version-url",
                "name" => "name"
              }
            }
          }
        end

        let(:decorator) { VerifiablePactDecorator.new(pact) }
        let(:pact) do
          double('pact',
            pending: true,
            wip: wip,
            name: "name",
            provider_name: "Bar",
            pending_provider_tags: pending_provider_tags,
            consumer_tags: consumer_tags)
        end
        let(:pending_provider_tags) { %w[dev] }
        let(:consumer_tags) { %w[dev] }
        let(:json) { decorator.to_json(options) }
        let(:options) { { user_options: { base_url: 'http://example.org', include_pending_status: include_pending_status } } }
        let(:include_pending_status) { true }
        let(:wip){ false }

        subject { JSON.parse(json) }

        it "generates a matching hash" do
          expect(subject).to match_pact(expected_hash)
        end

        it "creates the pact version url" do
          expect(decorator).to receive(:pact_version_url).with(pact, 'http://example.org')
          subject
        end

        it "creates the inclusion message" do
          expect(PactBroker::Pacts::VerifiablePactMessages).to receive(:new).with(pact, '/pact-version-url').and_call_original
          subject
        end

        context "when include_pending_status is false" do
          let(:include_pending_status) { false }
          let(:notices) { subject['verificationProperties']['notices'].collect{ | notice | notice['text'] } }

          it "does not include the pending flag" do
            expect(subject['verificationProperties']).to_not have_key('pending')
          end

          it "does not include the pending reason" do
            expect(subject['verificationProperties']).to_not have_key('pendingReason')
            expect(notices).to_not include(pending_reason)
          end

          it "does not include the pending notices" do
            expect(subject['verificationProperties']['notices'].size).to eq 1
          end
        end

        context "when wip is true" do
          let(:wip) { true }

          it "includes the wip flag" do
            expect(subject['verificationProperties']['wip']).to be true
          end
        end
      end
    end
  end
end
