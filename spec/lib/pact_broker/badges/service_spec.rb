require 'pact_broker/badges/service'
require 'webmock/rspec'

module PactBroker
  module Badges
    describe Service do
      let(:pacticipant_name) { "Foo-Bar_Thing Service" }
      let(:pact) { double("pact", consumer_name: "Foo-Bar", provider_name: "Thing_Blah") }
      let(:label) { nil }
      let(:initials) { false }
      let(:pseudo_branch_verification_status) { :success }
      let(:logger) { double('logger').as_null_object }
      let(:expected_url) { "https://img.shields.io/badge/#{expected_left_text}-#{expected_right_text}-#{expected_color}.svg" }
      let(:expected_color) { "brightgreen" }
      let(:expected_right_text) { "verified" }
      let(:expected_left_text) { "foo--bar%2Fthing__blah%20pact" }
      let(:response_status) { 200 }
      let!(:http_request) do
        stub_request(:get, expected_url).to_return(:status => response_status, :body => "svg")
      end
      let(:tags) { {} }

      subject { PactBroker::Badges::Service.pact_verification_badge(pact, label, initials, pseudo_branch_verification_status, tags) }

      let(:pact_verification_badge_url) { PactBroker::Badges::Service.pact_verification_badge_url(pact, label, initials, pseudo_branch_verification_status, tags) }

      before do
        Service.clear_cache
        allow(Service).to receive(:logger).and_return(logger)
      end

      describe "pact_verification_badge_url" do
        context "with the pact is nil" do
          let(:pact) { nil }
          let(:expected_left_text) { "pact%20not%20found" }
          let(:expected_right_text) { "unknown" }
          let(:expected_color) { "lightgrey" }
          let(:pseudo_branch_verification_status) { :never }

          it "returns a link to a 'pact not found' badge" do
            expect(pact_verification_badge_url).to eq URI(expected_url)
          end
        end
      end

      describe "#pact_verification_badge" do
        it "returns the svg file" do
           expect(subject).to eq "svg"
        end

        it "caches the response" do
          PactBroker::Badges::Service.pact_verification_badge pact, label, initials, pseudo_branch_verification_status
          PactBroker::Badges::Service.pact_verification_badge pact, label, initials, pseudo_branch_verification_status
          expect(http_request).to have_been_made.once
        end

        context "when the label is not specified" do
          it "creates a badge with the consumer and provider names" do
            subject
            expect(http_request).to have_been_made
            expect(pact_verification_badge_url).to eq URI(expected_url)
          end

          context "when initials is true" do
            let(:expected_left_text) { "fb%2Ftb%20pact" }
            let(:initials) { true }

            it "creates a badge with the consumer and provider initials" do
              subject
              expect(http_request).to have_been_made
              expect(pact_verification_badge_url).to eq URI(expected_url)
            end
          end

          context "when initials is true but the consumer and provider names only contain one word" do
            let(:expected_left_text) { "foo%2Fbar%20pact" }
            let(:initials) { true }
            let(:pact) { double("pact", consumer_name: "Foo", provider_name: "Bar") }

            it "creates a badge with the consumer and provider names, not initials" do
              subject
              expect(http_request).to have_been_made
              expect(pact_verification_badge_url).to eq URI(expected_url)
            end
          end

          context "when initials is true but the consumer and provider names are one camel cased word" do
            let(:expected_left_text) { "fa%2Fbp%20pact" }
            let(:initials) { true }
            let(:pact) { double("pact", consumer_name: "FooApp", provider_name: "barProvider") }

            it "creates a badge with the consumer and provider names, not initials" do
              subject
              expect(http_request).to have_been_made
              expect(pact_verification_badge_url).to eq URI(expected_url)
            end
          end

          context "when initials is true but the consumer and provider names are one camel cased word" do
            let(:expected_left_text) { "fa%2Fdat%20pact" }
            let(:initials) { true }
            let(:pact) { double("pact", consumer_name: "FooApp", provider_name: "doAThing") }

            it "creates a badge with the consumer and provider names, not initials" do
              subject
              expect(http_request).to have_been_made
              expect(pact_verification_badge_url).to eq URI(expected_url)
            end
          end

          context "when the tags are supplied" do
            let(:tags) { { consumer_tag: "prod", provider_tag: "master" } }

            let(:expected_left_text) { "foo--bar%20%28prod%29%2Fthing__blah%20%28master%29%20pact" }

            it "creates a badge with the consumer and provider names, not initials" do
              subject
              expect(http_request).to have_been_made
              expect(pact_verification_badge_url).to eq URI(expected_url)
            end
          end
        end

        context "when label is consumer" do
          let(:expected_left_text) { "foo--bar%20pact" }
          let(:label) { 'consumer' }

          it "creates a badge with only the consumer name" do
            subject
            expect(http_request).to have_been_made
            expect(pact_verification_badge_url).to eq URI(expected_url)
          end

          context "when initials is true" do
            let(:expected_left_text) { "fb%20pact" }
            let(:initials) { true }

            it "creates a badge with only the consumer initials" do
              subject
              expect(http_request).to have_been_made
              expect(pact_verification_badge_url).to eq URI(expected_url)
            end
          end
        end

        context "when label is provider" do
          let(:expected_left_text) { "thing__blah%20pact" }
          let(:label) { 'provider' }

          it "creates a badge with only the provider name" do
            subject
            expect(http_request).to have_been_made
            expect(pact_verification_badge_url).to eq URI(expected_url)
          end

          context "when initials is true" do
            let(:expected_left_text) { "tb%20pact" }
            let(:initials) { true }

            it "creates a badge with only the provider initials" do
              subject
              expect(http_request).to have_been_made
              expect(pact_verification_badge_url).to eq URI(expected_url)
            end
          end
        end

        context "when the pseudo_branch_verification_status is :success" do
          it "create a green badge with left text 'verified'" do
            subject
            expect(http_request).to have_been_made
            expect(pact_verification_badge_url).to eq URI(expected_url)
          end
        end

        context "when the pseudo_branch_verification_status is :never" do
          let(:pseudo_branch_verification_status) { :never }
          let(:expected_color) { "lightgrey" }
          let(:expected_right_text) { "unknown" }

          it "create a lightgrey badge with left text 'unknown'" do
            subject
            expect(http_request).to have_been_made
            expect(pact_verification_badge_url).to eq URI(expected_url)
          end
        end

        context "when the pseudo_branch_verification_status is :failed" do
          let(:pseudo_branch_verification_status) { :failed }
          let(:expected_color) { "red" }
          let(:expected_right_text) { "failed" }

          it "create a red badge with left text 'failed'" do
            subject
            expect(http_request).to have_been_made
            expect(pact_verification_badge_url).to eq URI(expected_url)
          end
        end

        context "when the pseudo_branch_verification_status is :stale" do
          let(:pseudo_branch_verification_status) { :stale }
          let(:expected_color) { "orange" }
          let(:expected_right_text) { "changed" }

          it "create a orange badge with left text 'changed'" do
            subject
            expect(http_request).to have_been_made
            expect(pact_verification_badge_url).to eq URI(expected_url)
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

          context "when the pseudo_branch_verification_status is success" do
            it "returns a static success image" do
              expect(subject).to include ">pact</"
              expect(subject).to include ">verified</"
            end
          end

          context "when the pseudo_branch_verification_status is failed" do
            let(:pseudo_branch_verification_status) { :failed }

            it "returns a static failed image" do
              expect(subject).to include ">pact</"
              expect(subject).to include ">failed</"
            end
          end

          context "when the pseudo_branch_verification_status is stale" do
            let(:pseudo_branch_verification_status) { :stale }

            it "returns a static stale image" do
              expect(subject).to include ">pact</"
              expect(subject).to include ">changed</"
            end
          end

          context "when the pseudo_branch_verification_status is never" do
            let(:pseudo_branch_verification_status) { :never }

            it "returns a static stale image" do
              expect(subject).to include ">pact</"
              expect(subject).to include ">unknown</"
            end
          end
        end

        context "when a timeout exception is raised connecting to the shields.io server" do
          before do
            allow(Net::HTTP).to receive(:start).and_raise(Net::OpenTimeout)
          end

          it "logs a warning rather than an error as this will happen reasonably often" do
            expect(logger).to receive(:warn).with(/Timeout retrieving badge from.*shield.*Net::OpenTimeout/)
            subject
          end

          it "returns a static image" do
            expect(subject).to include ">pact</"
          end

          it "does not cache the response" do
            expect(Service::CACHE.size).to eq 0
          end
        end

        context "when an exception is raised connecting to the shields.io server" do
          before do
            allow(Net::HTTP).to receive(:start).and_raise("an error")
          end

          it "logs the error" do
            expect(logger).to receive(:warn).with(/Error retrieving badge from.*shield.*/, RuntimeError)
            subject
          end

          it "returns a static image" do
            expect(subject).to include ">pact</"
          end

          it "does not cache the response" do
            expect(Service::CACHE.size).to eq 0
          end
        end

        context "when the shields_io_base_url is not configured" do
          before do
            PactBroker.configuration.shields_io_base_url = nil
          end

          it "does not make an http request" do
            subject
            expect(http_request).to_not have_been_made
          end

          it "returns a static image" do
            expect(subject).to include ">pact</"
            expect(subject).to include ">verified</"
          end
        end
      end
    end
  end
end
