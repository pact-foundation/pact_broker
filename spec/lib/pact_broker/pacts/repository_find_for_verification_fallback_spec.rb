require 'pact_broker/pacts/repository'

module PactBroker
  module Pacts
    describe Repository do
      let(:td) { TestDataBuilder.new }

      describe "#find_for_verification" do
        def find_by_consumer_version_number(consumer_version_number)
          subject.find{ |pact| pact.consumer_version_number == consumer_version_number }
        end

        def find_by_consumer_name_and_consumer_version_number(consumer_name, consumer_version_number)
          subject.find{ |pact| pact.consumer_name == consumer_name && pact.consumer_version_number == consumer_version_number }
        end

        subject { Repository.new.find_for_verification("Bar", consumer_version_selectors) }

        context "when there is a fallback tag specified" do
          before do
            td.create_pact_with_consumer_version_tag("Foo", "1", "master", "Bar")
              .create_pact_with_consumer_version_tag("Foo", "2", "feat-x", "Bar")
          end

          let(:tag) { "feat-x" }
          let(:fallback_tag) { "master" }
          let(:selector) { Selector.new(tag: tag, fallback_tag: fallback_tag, latest: true) }
          let(:consumer_version_selectors) { Selectors.new(selector) }

          context "when a pact exists for the main tag" do
            it "returns the pact with the main tag" do
              expect(find_by_consumer_version_number("2")).to_not be nil
              expect(find_by_consumer_version_number("2").selectors.first).to eq Selector.latest_for_tag(tag).resolve(PactBroker::Domain::Version.for("Foo", "2"))
            end

            it "does not set the fallback_tag on the selector" do
              expect(find_by_consumer_version_number("2").selectors.first.fallback_tag).to be nil
            end
          end

          context "when a pact does not exist for the main tag and pact exists for the fallback tag" do
            let(:tag) { "no-existy" }

            it "returns the pact with the fallback tag" do
              expect(find_by_consumer_version_number("1")).to_not be nil
            end

            it "sets the fallback_tag on the selector" do
              expect(find_by_consumer_version_number("1").selectors.first.fallback_tag).to eq fallback_tag
            end

            it "sets the tag on the selector" do
              expect(find_by_consumer_version_number("1").selectors.first.tag).to eq tag
            end

            it "sets the latest flag on the selector" do
              expect(find_by_consumer_version_number("1").selectors.first.latest).to be true
            end

            context "when a consumer is specified" do
              before do
                td.create_pact_with_consumer_version_tag("Foo2", "3", "master", "Bar")
              end

              let(:selector) { Selector.new(tag: tag, fallback_tag: fallback_tag, latest: true, consumer: "Foo") }

              it "only returns the pacts for the consumer" do
                expect(subject.size).to eq 1
                expect(subject.first.consumer.name).to eq "Foo"
                expect(subject.first.selectors.first).to eq selector.resolve_for_fallback(PactBroker::Domain::Version.for("Foo", "1"))
              end
            end
          end

          context "when a pact does not exist for either tag or fallback_tag" do
            let(:tag) { "no-existy" }
            let(:fallback_tag) { "also-no-existy" }

            it "returns an empty list" do
              expect(subject).to be_empty
            end
          end
        end
      end
    end
  end
end
