require "pact_broker/pacts/repository"

module PactBroker
  module Pacts
    describe Repository do
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

        context "when there is a fallback branch specified" do
          before do
            td.create_consumer("Foo")
              .create_provider("Bar")
              .create_consumer_version("1", branch: "main")
              .create_pact
              .create_consumer_version("2", branch: "feat-x")
              .create_pact
          end

          let(:branch) { "feat-x" }
          let(:fallback_branch) { "main" }
          let(:selector) { Selector.new(branch: branch, fallback_branch: fallback_branch, latest: true) }
          let(:consumer_version_selectors) { Selectors.new(selector) }

          context "when a pact exists for the branch" do
            it "returns the pact from the branch" do
              expect(subject.size).to eq 1
              expect(find_by_consumer_version_number("2")).to_not be nil
            end

            it "does not set the fallback_branch on the selector" do
              expect(find_by_consumer_version_number("2").selectors.first.fallback_branch).to be nil
            end
          end

          context "when a pact does not exist for the branch and a pact exists for the fallback branch" do
            let(:branch) { "no-existy" }

            it "returns the pact from the fallback branch" do
              expect(subject.size).to eq 1
              expect(find_by_consumer_version_number("1")).to_not be nil
            end

            it "sets the branch, fallback_branch and latest on the selector" do
              selector = find_by_consumer_version_number("1").selectors.first
              expect(selector.branch).to eq branch
              expect(selector.fallback_branch).to eq fallback_branch
              expect(selector.latest).to be true
            end

            context "when a consumer is specified" do
              before do
                td.create_consumer("Foo2")
                  .create_consumer_version("3", branch: "main")
                  .create_pact
              end

              let(:selector) { Selector.new(branch: branch, fallback_branch: fallback_branch, latest: true, consumer: "Foo") }

              it "only returns the pacts for the consumer" do
                expect(subject.size).to eq 1
                expect(subject.first.consumer.name).to eq "Foo"
              end
            end
          end

          context "when one consumer has a pact for the branch and another consumer only has a pact for the fallback branch" do
            before do
              td.create_consumer("Foo2")
                .create_consumer_version("3", branch: "main")
                .create_pact
            end

            it "returns the branch pact for the first consumer and the fallback pact for the other consumer" do
              expect(subject.collect { | pact | [pact.consumer.name, pact.consumer_version_number] }).to contain_exactly(["Foo", "2"], ["Foo2", "3"])
            end

            it "only sets the fallback_branch on the selector for the fallback pact" do
              expect(find_by_consumer_version_number("2").selectors.first.fallback_branch).to be nil
              expect(find_by_consumer_version_number("3").selectors.first.fallback_branch).to eq fallback_branch
            end

            context "when the selector specifies the consumer that has a pact for the fallback branch only" do
              let(:selector) { Selector.new(branch: branch, fallback_branch: fallback_branch, latest: true, consumer: "Foo2") }

              it "returns the fallback pact" do
                expect(subject.collect { | pact | [pact.consumer.name, pact.consumer_version_number] }).to eq [["Foo2", "3"]]
              end
            end
          end

          context "when a pact does not exist for either branch or fallback_branch" do
            let(:branch) { "no-existy" }
            let(:fallback_branch) { "also-no-existy" }

            it "returns an empty list" do
              expect(subject).to be_empty
            end
          end
        end

        context "when fallbackToMainBranch is specified" do
          before do
            td.create_consumer("Foo", main_branch: "main")
              .create_provider("Bar")
              .create_consumer_version("1", branch: "main")
              .create_pact
              .create_consumer_version("2", branch: "feat-x")
              .create_pact
              .create_consumer("Foo2", main_branch: "develop")
              .create_consumer_version("3", branch: "develop")
              .create_pact
              .create_consumer_version("4", branch: "main")
              .create_pact
          end

          let(:branch) { "feat-x" }
          let(:selector) { Selector.new(branch: branch, fallback_to_main_branch: true, latest: true) }
          let(:consumer_version_selectors) { Selectors.new(selector) }

          it "returns the branch pact for the consumer that has one, and the pact from the main branch of each other consumer" do
            expect(subject.collect { | pact | [pact.consumer.name, pact.consumer_version_number] }).to contain_exactly(["Foo", "2"], ["Foo2", "3"])
          end

          it "does not set a fallback branch on the selector for the branch pact" do
            expect(find_by_consumer_version_number("2").selectors.first.fallback_branch).to be nil
          end

          it "sets the fallback branch to the consumer's main branch on the selector for the fallback pact" do
            selector = find_by_consumer_version_number("3").selectors.first
            expect(selector.branch).to eq branch
            expect(selector.fallback_branch).to eq "develop"
            expect(selector.latest).to be true
            expect(selector.fallback_to_main_branch).to be nil
          end

          context "when no consumer has a pact for the branch" do
            let(:branch) { "no-existy" }

            it "returns the pact from the main branch of each consumer" do
              expect(subject.collect { | pact | [pact.consumer.name, pact.consumer_version_number] }).to contain_exactly(["Foo", "1"], ["Foo2", "3"])
            end
          end

          context "when a consumer is specified" do
            let(:branch) { "no-existy" }
            let(:selector) { Selector.new(branch: branch, fallback_to_main_branch: true, latest: true, consumer: "Foo2") }

            it "only returns the pact for that consumer" do
              expect(subject.collect { | pact | [pact.consumer.name, pact.consumer_version_number] }).to eq [["Foo2", "3"]]
            end
          end

          context "when a consumer does not have a main branch configured" do
            let(:branch) { "no-existy" }

            before do
              td.create_consumer("Foo3")
                .create_consumer_version("5", branch: "some-branch")
                .create_pact
            end

            it "does not return a fallback pact for that consumer" do
              expect(subject.collect(&:consumer_name)).to_not include("Foo3")
            end
          end
        end
      end
    end
  end
end
