require 'pact_broker/badges/cached_service'
require 'pact_broker/badges/service'

module PactBroker
  module Badges
    describe CachedService do

      let(:consumer) { double('consumer', name: 'foo') }
      let(:provider) { double('provider', name: 'bar') }
      let(:pact) { double('pact', consumer: consumer, provider: provider) }
      let(:label) { 'consumer' }
      let(:initials) { false }
      let(:verification_status) { 'status' }

      describe "#pact_verification_badge" do

        before do
          allow(Service).to receive(:pact_verification_badge).and_return('badge')
          stub_const('PactBroker::Badges::CachedService::CACHE', {})
        end

        subject { CachedService.pact_verification_badge pact, label, initials, verification_status  }

        it "returns the badge" do
          expect(subject).to eq 'badge'
        end

        context "when the badge is not in the cache" do
          before do
            stub_const('PactBroker::Badges::CachedService::CACHE', {})
          end

          it "retrieves the badge from the Badges::Service" do
            expect(Service).to receive(:pact_verification_badge)
            subject
          end
        end

        context "when the badge is in the cache" do
          it "returns the cached badge" do
            expect(Service).to receive(:pact_verification_badge).once
            CachedService.pact_verification_badge pact, label, initials, verification_status
            CachedService.pact_verification_badge pact, label, initials, verification_status
          end
        end
      end
    end
  end
end
