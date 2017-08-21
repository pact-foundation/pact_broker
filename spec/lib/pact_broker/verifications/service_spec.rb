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
        let(:params) { {'success' => true, 'providerApplicationVersion' => '4.5.6'} }
        let(:pact) { TestDataBuilder.new.create_pact_with_hierarchy.and_return(:pact) }
        let(:create_verification) { subject.create 3, params, pact }

        it "logs the creation" do
          allow(PactBroker.logger).to receive(:info).and_call_original
          expect(PactBroker.logger).to receive(:info).with(/.*verification.*3.*success/)
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
