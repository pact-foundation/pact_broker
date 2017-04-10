require 'pact_broker/verifications/service'
require 'pact_broker/verifications/repository'

module PactBroker

  module Verifications
    describe Service do

      subject { PactBroker::Verifications::Service }

      describe "#next_number_for" do

        let(:pact) { double(:pact) }

        before do
          allow_any_instance_of(PactBroker::Verifications::Repository).to receive(:verification_count_for_pact).and_return(2)
        end

        it "returns the number for the next build to be recorded for a pact" do
          expect(subject.next_number_for(pact)).to eq 3
        end
      end

      describe "#create" do
        let(:json) { {'success' => true} }
        let(:pact) { ProviderStateBuilder.new.create_pact_with_hierarchy }
        let(:create_verification) { subject.create 3, json, pact }

        it "logs the creation" do
          allow(PactBroker.logger).to receive(:info).and_call_original
          expect(PactBroker.logger).to receive(:info).with(/.*verification.*3.*success/)
          create_verification
        end

        it "foo" do
          verification = create_verification
          expect(verification.success).to be true
          expect(verification.number).to eq 3
        end
      end
    end
  end

end
