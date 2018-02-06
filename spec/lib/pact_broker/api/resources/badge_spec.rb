require 'pact_broker/api/resources/badge'
require 'pact_broker/badges/service'
require 'pact_broker/matrix/service'

module PactBroker
  module Api
    module Resources
      describe Badge do
        let(:path) { "/pacts/provider/provider/consumer/consumer/latest/badge" }
        let(:params) { {} }

        before do
          allow(PactBroker::Pacts::Service).to receive(:find_latest_pact).and_return(pact)
          allow(PactBroker::Verifications::Service).to receive(:find_latest_verification_for).and_return(verification)
          allow(PactBroker::Badges::Service).to receive(:pact_verification_badge).and_return("badge")
          allow(PactBroker::Verifications::Status).to receive(:new).and_return(verification_status)
        end

        let(:pact) { instance_double("PactBroker::Domain::Pact", consumer: consumer, provider: provider, consumer_version_number: "2") }
        let(:consumer) { double('consumer') }
        let(:provider) { double('provider') }
        let(:verification) { double("verification", provider_version_number: "3") }
        let(:verification_status) { instance_double("PactBroker::Verifications::Status", to_sym: :verified) }


        subject { get path, params, {'HTTP_ACCEPT' => 'image/svg+xml'}; last_response }

        context "when enable_public_badge_access is false and the request is not authenticated" do
          before do
            PactBroker.configuration.enable_public_badge_access = false
            allow_any_instance_of(Badge).to receive(:authenticated?).and_return(false)
          end

          it "returns a 401" do
            expect(subject.status).to eq 401
          end
        end

        context "when enable_public_badge_access is false but the request is authenticated" do
          before do
            PactBroker.configuration.enable_public_badge_access = false
            allow_any_instance_of(Badge).to receive(:authenticated?).and_return(true)
          end

          it "returns a 200" do
            expect(subject.status).to eq 200
          end
        end

        context "when enable_public_badge_access is true" do

          before do
            PactBroker.configuration.enable_public_badge_access = true
          end

          it "retrieves the latest pact" do
            expect(PactBroker::Pacts::Service).to receive(:find_latest_pact)
            subject
          end

          it "retrieves the latest verification for the pact's consumer and provider" do
            expect(PactBroker::Verifications::Service).to receive(:find_latest_verification_for).with(consumer, provider, nil)
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

          it "does not allow caching" do
            expect(subject.headers['Cache-Control']).to eq 'no-cache'
          end

          it "returns the badge" do
            expect(subject.body).to end_with "badge"
          end

          it "returns a comment with the consumer and provider numbers" do
            expect(subject.body).to include "<!-- consumer version 2 provider version 3 -->"
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

          context "when retrieving the badge for the latest pact with a tag" do
            let(:path) { "/pacts/provider/provider/consumer/consumer/latest/prod/badge" }

            it "retrieves the latest verification for the pact's consumer and provider and specified tag" do
              expect(PactBroker::Verifications::Service).to receive(:find_latest_verification_for).with(anything, anything, 'prod')
              subject
            end
          end

          context "when retrieving the badge for a matrix row by tag" do
            before do
              allow(PactBroker::Matrix::Service).to receive(:find_for_consumer_and_provider_with_tags).and_return(row)
              allow(PactBroker::Verifications::Service).to receive(:find_by_id).and_return(verification)
            end

            let(:path) { "/matrix/provider/provider/latest/master/consumer/consumer/latest/prod/badge" }
            let(:row) { { consumer_name: 'consumer', provider_name: 'provider' } }

            it "looks up the verification" do
              expect(PactBroker::Verifications::Service).to receive(:find_latest_verification_for_tags) do | consumer, provider, tag|
                expect(consumer.name).to eq 'consumer'
                expect(provider.name).to eq 'provider'
                expect(tag).to eq 'prod'
              end
              subject
            end


            context "when a verification is found" do
              before do
                allow(PactBroker::Verifications::Service).to receive(:find_latest_verification_for_tags).and_return(verification)
              end

              it "returns the badge" do
                expect(subject.body).to end_with "badge"
              end
            end

            context "when a verification is not found" do
              before do
                allow(PactBroker::Verifications::Service).to receive(:find_latest_verification_for_tags).and_return(nil)
              end

              it "returns the badge" do
                expect(subject.body).to end_with "badge"
              end
            end
          end
        end
      end
    end
  end
end
