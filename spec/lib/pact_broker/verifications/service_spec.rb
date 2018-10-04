require 'pact_broker/verifications/service'
require 'pact_broker/verifications/repository'

module PactBroker

  module Verifications
    describe Service do
      before do
        allow(Service).to receive(:logger).and_return(logger)
      end

      let(:logger) { double('logger').as_null_object }

      subject { PactBroker::Verifications::Service }

      describe "#create" do
        before do
          allow(PactBroker::Webhooks::Service).to receive(:trigger_webhooks)
        end

        let(:params) { {'success' => true, 'providerApplicationVersion' => '4.5.6'} }
        let(:pact) { TestDataBuilder.new.create_pact_with_hierarchy.and_return(:pact) }
        let(:create_verification) { subject.create 3, params, pact }

        it "logs the creation" do
          expect(logger).to receive(:info).with(/.*verification.*3.*success/)
          create_verification
        end

        it "sets the verification attributes" do
          verification = create_verification
          expect(verification.success).to be true
          expect(verification.number).to eq 3
        end

        it "sets the pact content for the verification" do
          verification = create_verification
          expect(verification.pact_version_id).to_not be_nil
          expect(verification.pact_version).to_not be_nil
        end

        it "sets the provider version" do
          verification = create_verification
          expect(verification.provider_version).to_not be nil
          expect(verification.provider_version_number).to eq '4.5.6'
        end

        it "invokes the webhooks for the verification" do
          verification = create_verification
          expect(PactBroker::Webhooks::Service).to have_received(:trigger_webhooks).with(pact, verification, PactBroker::Webhooks::WebhookEvent::VERIFICATION_PUBLISHED)
        end
      end

      describe "#errors" do
        let(:params) { {} }

        it "returns errors" do
          expect(subject.errors(params)).to_not be_empty
        end

        it "returns something that responds to :messages" do
          expect(subject.errors(params).messages).to_not be_empty
        end
      end
    end
  end
end
