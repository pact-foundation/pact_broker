require 'pact_broker/badges/service'
require 'webmock/rspec'

module PactBroker
  module Badges
    module Service
      describe "#pact_verification_badge" do
        let(:pacticipant_name) { "Foo-Bar_Thing Service" }
        let(:pact) { double("pact", consumer_name: "Foo-Bar", provider_name: "Thing_Blah") }
        let(:pacticipant_role) { nil }
        let(:verification_status) { :success }

        let(:expected_url) { "https://img.shields.io/badge/#{expected_left_text}-#{expected_right_text}-#{expected_color}.svg" }
        let(:expected_color) { "brightgreen" }
        let(:expected_right_text) { "verified" }
        let(:expected_left_text) { "foo--bar%2Fthing__blah%20pact" }
        let(:response_status) { 200 }
        let!(:http_request) do
          stub_request(:get, expected_url).to_return(:status => response_status, :body => "svg")
        end

        let(:subject) { PactBroker::Badges::Service.pact_verification_badge pact, pacticipant_role, verification_status }

        it "returns the svg file" do
           expect(subject).to eq "svg"
        end

        context "when the pacticipant_role is not specified" do
          it "creates a badge with the consumer and provider names" do
            subject
            expect(http_request).to have_been_made
          end
        end

        context "when pacticipant_role is consumer" do
          let(:expected_left_text) { "thing__blah%20pact" }
          let(:pacticipant_role) { 'consumer' }

          it "creates a badge with the provider name" do
            subject
            expect(http_request).to have_been_made
          end
        end

        context "when pacticipant_role is provider" do
          let(:expected_left_text) { "foo--bar%20pact" }
          let(:pacticipant_role) { 'provider' }

          it "creates a badge with the consumer name" do
            subject
            expect(http_request).to have_been_made
          end
        end

        context "when the verification_status is :success" do
          it "create a green badge with left text 'verified'" do
            subject
            expect(http_request).to have_been_made
          end
        end

        context "when the verification_status is :never" do
          let(:verification_status) { :never }
          let(:expected_color) { "lightgrey" }
          let(:expected_right_text) { "unknown" }

          it "create a lightgrey badge with left text 'unknown'" do
            subject
            expect(http_request).to have_been_made
          end
        end

        context "when the verification_status is :failed" do
          let(:verification_status) { :failed }
          let(:expected_color) { "red" }
          let(:expected_right_text) { "failed" }

          it "create a red badge with left text 'failed'" do
            subject
            expect(http_request).to have_been_made
          end
        end

        context "when the verification_status is :stale" do
          let(:verification_status) { :stale }
          let(:expected_color) { "orange" }
          let(:expected_right_text) { "unknown" }

          it "create a orange badge with left text 'unknown'" do
            subject
            expect(http_request).to have_been_made
          end
        end

        context "when the pact is nil" do
          let(:pact) { nil }
          it "does not make a dynamic badge" do
            subject
            expect(http_request).to_not have_been_made
          end

          it "returns a static image" do
            expect(subject).to include ">pact not found</"
            expect(subject).to include ">unknown</"
          end
        end

        context "when a non-200 response is returned" do
          let(:expected_url) { /http/ }
          let(:response_status) { 404 }

          context "when the verification_status is success" do
            it "returns a static success image" do
              expect(subject).to include ">pact</"
              expect(subject).to include ">verified</"
            end
          end

          context "when the verification_status is failed" do
            let(:verification_status) { :failed }

            it "returns a static failed image" do
              expect(subject).to include ">pact</"
              expect(subject).to include ">failed</"
            end
          end

          context "when the verification_status is stale" do
            let(:verification_status) { :stale }

            it "returns a static stale image" do
              expect(subject).to include ">pact</"
              expect(subject).to include ">unknown</"
            end
          end

          context "when the verification_status is never" do
            let(:verification_status) { :never }

            it "returns a static stale image" do
              expect(subject).to include ">pact</"
              expect(subject).to include ">unknown</"
            end
          end
        end

        context "when an exception is raised connecting to the shields.io server" do
          before do
            allow(Net::HTTP).to receive(:start).and_raise("an error")
          end

          it "logs the error" do
            expect(PactBroker.logger).to receive(:error).with(/Error retrieving badge from.*shield.*an error/)
            subject
          end

          it "returns a static image" do
            expect(subject).to include ">pact</"
          end
        end
      end
    end
  end
end
