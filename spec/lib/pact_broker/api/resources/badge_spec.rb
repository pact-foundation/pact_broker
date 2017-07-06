require 'pact_broker/api/resources/badge'
require 'pact_broker/badges/service'

module PactBroker
  module Api
    module Resources
      describe Badge do
        let(:path) { "/pacts/provider/provider/consumer/consumer/latest/badge" }
        let(:params) { {} }

        subject { get path, params, {'HTTP_ACCEPT' => 'image/svg+xml'}; last_response }

        context "when enable_badge_resources is false" do
          before do
            PactBroker.configuration.enable_badge_resources = false
          end

          it "returns a 404" do
            expect(subject.status).to eq 404
          end
        end

        context "when enable_badge_resources is true" do
          before do
            PactBroker.configuration.enable_badge_resources = true
            allow(PactBroker::Pacts::Service).to receive(:find_latest_pact).and_return(pact)
            allow(PactBroker::Verifications::Service).to receive(:find_latest_verification_for).and_return(verification)
            allow(PactBroker::Badges::Service).to receive(:pact_verification_badge).and_return("badge")
            allow(PactBroker::Verifications::Status).to receive(:new).and_return(verification_status)
          end

          let(:pact) { instance_double("PactBroker::Domain::Pact", consumer: consumer, provider: provider) }
          let(:consumer) { double('consumer') }
          let(:provider) { double('provider') }
          let(:verification) { double("verification") }
          let(:verification_status) { instance_double("PactBroker::Verifications::Status", to_sym: :verified) }

          it "retrieves the latest pact" do
            expect(PactBroker::Pacts::Service).to receive(:find_latest_pact)
            subject
          end

          it "retrieves the latest verification for the pact's consumer and provider" do
            expect(PactBroker::Verifications::Service).to receive(:find_latest_verification_for).with(consumer, provider)
            subject
          end

          it "determines the pact's verification status based on the latest pact and latest verification" do
            expect(PactBroker::Verifications::Status).to receive(:new).with(pact, verification)
            subject
          end

          it "creates a badge" do
            expect(PactBroker::Badges::Service).to receive(:pact_verification_badge).with(pact, nil, false, :verified)
            subject
          end

          it "returns a 200 status" do
            expect(subject.status).to eq 200
          end

          it "returns the badge" do
            expect(subject.body).to eq "badge"
          end

          context "when the label param is specified" do
            let(:params) { {label: 'consumer'} }

            it "creates a badge with the specified label" do
              expect(PactBroker::Badges::Service).to receive(:pact_verification_badge).with(anything, 'consumer', anything, anything)
              subject
            end
          end

          context "when the initials param is true" do
            let(:params) { {initials: 'true'} }

            it "creates a badge with initials" do
              expect(PactBroker::Badges::Service).to receive(:pact_verification_badge).with(anything, anything, true, anything)
              subject
            end
          end

          context "when the pact is not found" do
            let(:pact) { nil }

            it "returns a 200 status" do
              expect(subject.status).to eq 200
            end
          end
        end
      end
    end
  end
end
