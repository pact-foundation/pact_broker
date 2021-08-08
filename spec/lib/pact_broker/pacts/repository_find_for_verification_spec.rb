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

        context "when there are no selectors" do

          let(:foo_main_branch) { nil }

          let(:consumer_version_selectors) { Selectors.new }

          context "when there is no main branch version" do
            before do
              td.create_consumer("Foo")
                .create_pact_with_hierarchy("Foo", "foo-latest-prod-version", "Bar")
                .create_consumer_version_tag("prod")
                .create_consumer_version("not-latest-dev-version", tag_names: ["dev"])
                .comment("next pact not selected")
                .create_pact
                .create_consumer_version("foo-latest-dev-version", tag_names: ["dev"])
                .create_pact
                .create_consumer("Baz")
                .create_consumer_version("baz-latest-dev-version", tag_names: ["dev"])
                .create_pact
            end

            it "returns the latest pact for each consumer" do
              expect(subject.size).to eq 2
              expect(find_by_consumer_name_and_consumer_version_number("Foo", "foo-latest-dev-version")).to_not be nil
              expect(find_by_consumer_name_and_consumer_version_number("Baz", "baz-latest-dev-version")).to_not be nil
              expect(subject.all?(&:overall_latest?)).to be true
            end
          end

          context "when there is a version from the main branch" do
            before do
              td.create_consumer("Foo", main_branch: "main")
                .create_consumer_version("1", branch: "main")
                .create_provider("Bar")
                .create_pact
                .create_pact_with_hierarchy("Foo", "2", "Bar")
            end

            it "returns the latest version from the main branch" do
              expect(subject.size).to eq 1
              expect(find_by_consumer_name_and_consumer_version_number("Foo", "1")).to_not be_nil
              expect(subject.first.selectors.first).to be_latest_for_main_branch
            end
          end

          context "when there is a version with a tag with the name of the main branch" do
            before do
              td.create_consumer("Foo", main_branch: "main")
                .create_consumer_version("1", tag_name: "main")
                .create_provider("Bar")
                .create_pact
                .create_pact_with_hierarchy("Foo", "2", "Bar")
            end

            it "returns the latest version from the main branch" do
              expect(subject.size).to eq 1
              expect(find_by_consumer_name_and_consumer_version_number("Foo", "1")).to_not be_nil
              expect(subject.first.selectors.first).to be_latest_for_tag
              expect(subject.first.selectors.first.tag).to eq "main"
            end
          end

          context "when there is a not version from the main branch" do
            before do
              td.create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_pact_with_hierarchy("Foo", "2", "Bar")
            end

            it "returns the latest version from the main branch" do
              expect(subject.size).to eq 1
              expect(find_by_consumer_name_and_consumer_version_number("Foo", "2")).to_not be_nil
              expect(subject.first.selectors.first).to be_overall_latest
            end
          end

          context "when there are currently deployed versons" do
            before do
              td.create_environment("test")
                .create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_deployed_version_for_consumer_version(currently_deployed: false)
                .create_pact_with_hierarchy("Foo", "2", "Bar")
                .create_deployed_version_for_consumer_version
                .create_pact_with_hierarchy("Foo", "3", "Bar")
            end

            it "returns the currently deployed pacts" do
              expect(find_by_consumer_name_and_consumer_version_number("Foo", "1")).to be_nil
              expect(find_by_consumer_name_and_consumer_version_number("Foo", "2")).to_not be_nil
              expect(find_by_consumer_name_and_consumer_version_number("Foo", "2").selectors.first).to be_currently_deployed
            end
          end

          context "when there are currently released+supported versions" do
            before do
              td.create_environment("test")
                .create_pact_with_hierarchy("Foo", "1", "Bar")
                .create_released_version_for_consumer_version(currently_supported: false)
                .create_pact_with_hierarchy("Foo", "2", "Bar")
                .create_released_version_for_consumer_version
                .create_pact_with_hierarchy("Foo", "3", "Bar")
            end

            it "returns the currently deployed pacts" do
              expect(find_by_consumer_name_and_consumer_version_number("Foo", "1")).to be_nil
              expect(find_by_consumer_name_and_consumer_version_number("Foo", "2")).to_not be_nil
              expect(find_by_consumer_name_and_consumer_version_number("Foo", "2").selectors.first).to be_currently_supported
            end
          end
        end

        context "when the selector is latest: true" do
          let(:pact_selector_1) { Selector.overall_latest }
          let(:consumer_version_selectors) do
            Selectors.new(pact_selector_1)
          end

          before do
            td.create_pact_with_hierarchy("Foo1", "1", "Bar")
              .create_pact_with_hierarchy("Foo1", "2", "Bar")
              .create_pact_with_hierarchy("Foo2", "3", "Bar")
              .create_pact_with_hierarchy("Foo2", "4", "Bar2")
          end

          it "returns the latest pact for each consumer" do
            expect(subject.size).to eq 2
            expect(find_by_consumer_name_and_consumer_version_number("Foo1", "2").selectors).to eq [Selector.overall_latest.resolve(PactBroker::Domain::Version.find(number: "2"))]
            expect(find_by_consumer_name_and_consumer_version_number("Foo2", "3").selectors).to eq [Selector.overall_latest.resolve(PactBroker::Domain::Version.find(number: "3"))]
          end
        end

        context "when the selector is latest: true for a particular consumer" do
          let(:pact_selector_1) { Selector.latest_for_consumer("Foo1") }

          let(:consumer_version_selectors) do
            Selectors.new(pact_selector_1)
          end

          before do
            td.create_pact_with_hierarchy("Foo1", "1", "Bar")
              .create_pact_with_hierarchy("Foo1", "2", "Bar")
              .create_pact_with_hierarchy("Foo2", "2", "Bar")
              .create_pact_with_hierarchy("Foo2", "2", "Bar2")
          end

          it "returns the latest pact for each consumer" do
            expect(subject.size).to eq 1
            expect(find_by_consumer_name_and_consumer_version_number("Foo1", "2").selectors).to eq [pact_selector_1.resolve(PactBroker::Domain::Version.for("Foo1", "2"))]
          end
        end

        context "when the selector is latest: true, with a tag, for a particular consumer" do
          let(:pact_selector_1) { Selector.latest_for_tag_and_consumer("prod", "Foo1") }

          let(:consumer_version_selectors) do
            Selectors.new(pact_selector_1)
          end

          before do
            td.create_pact_with_hierarchy("Foo1", "1", "Bar")
              .create_consumer_version_tag("prod")
              .create_pact_with_hierarchy("Foo1", "2", "Bar")
              .create_pact_with_hierarchy("Foo2", "2", "Bar")
              .create_consumer_version_tag("prod")
              .create_pact_with_hierarchy("Foo2", "2", "Bar2")
          end

          it "returns the latest pact for each consumer" do
            expect(subject.size).to eq 1
            expected_consumer_version = PactBroker::Domain::Version.where_pacticipant_name("Foo1").where(number: "1").single_record
            expect(find_by_consumer_name_and_consumer_version_number("Foo1", "1").selectors).to eq [pact_selector_1.resolve(expected_consumer_version)]
          end
        end

        context "when the latest consumer tag names are specified" do
          before do
            td.create_pact_with_hierarchy("Foo", "foo-latest-prod-version", "Bar")
              .create_consumer_version_tag("prod")
              .create_consumer_version("not-latest-dev-version", tag_names: ["dev"])
              .comment("next pact not selected")
              .create_pact
              .create_consumer_version("foo-latest-dev-version", tag_names: ["dev"])
              .create_pact
              .create_consumer("Baz")
              .create_consumer_version("baz-latest-dev-version", tag_names: ["dev"])
              .create_consumer_version_tag("prod")
              .create_pact
          end

          let(:pact_selector_1) { Selector.latest_for_tag("dev") }
          let(:pact_selector_2) { Selector.latest_for_tag("prod") }
          let(:consumer_version_selectors) do
            Selectors.new(pact_selector_1, pact_selector_2)
          end
          let(:expected_sorted_selectors) do
            [
              ResolvedSelector.new({ tag: "dev", latest: true }, PactBroker::Domain::Version.for("Baz", "baz-latest-dev-version")),
              ResolvedSelector.new({ tag: "prod", latest: true }, PactBroker::Domain::Version.for("Baz", "baz-latest-dev-version"))
            ]
          end

          it "returns the latest pact with the specified tags for each consumer" do
            expect(find_by_consumer_version_number("foo-latest-prod-version").selectors).to eq [Selector.latest_for_tag("prod").resolve(PactBroker::Domain::Version.for("Foo", "foo-latest-prod-version"))]
            expect(find_by_consumer_version_number("foo-latest-dev-version").selectors).to eq [Selector.latest_for_tag("dev").resolve(PactBroker::Domain::Version.for("Foo", "foo-latest-dev-version"))]
            expect(find_by_consumer_version_number("baz-latest-dev-version").selectors.sort_by{ |s| s[:tag] }).to eq expected_sorted_selectors
            expect(subject.size).to eq 3
          end

          it "sets the latest_consumer_version_tag_names" do
            expect(find_by_consumer_version_number("foo-latest-prod-version").selectors.collect(&:tag)).to eq ["prod"]
          end

          context "when a consumer name is specified" do
            before do
              td.create_pact_with_hierarchy("Foo", "2", "Bar")
                .create_consumer_version_tag("prod")
                .create_pact_with_hierarchy("Foo", "3", "Bar")
                .create_consumer_version_tag("prod")
                .create_consumer_version("4")
                .create_consumer_version_tag("prod")
                .republish_same_pact
            end

            let(:consumer_version_selectors) do
              Selectors.new(Selector.all_for_tag_and_consumer("prod", "Foo"))
            end

            it "returns all the pacts with that tag for that consumer" do
              expect(subject.size).to eq 3
              expect(find_by_consumer_version_number("foo-latest-prod-version").selectors).to eq [Selector.all_for_tag_and_consumer("prod", "Foo").resolve(PactBroker::Domain::Version.for("Foo", "foo-latest-prod-version"))]
            end

            it "includes all the selectors when the same pact content is selected multiple times (used to just use the latest, not sure about this)" do
              expect(find_by_consumer_version_number("3")).to be nil
              expect(find_by_consumer_version_number("4").selectors.first).to eq Selector.all_for_tag_and_consumer("prod", "Foo").resolve(PactBroker::Domain::Version.for("Foo", "3"))
              expect(find_by_consumer_version_number("4").selectors.last).to eq Selector.all_for_tag_and_consumer("prod", "Foo").resolve(PactBroker::Domain::Version.for("Foo", "4"))
            end
          end
        end

        context "when all versions with a given tag are requested" do
          before do
            td.create_pact_with_hierarchy("Foo2", "prod-version-1", "Bar2")
              .create_consumer_version_tag("prod")
              .create_consumer_version("not-prod-version", tag_names: %w[master])
              .create_pact
              .create_consumer_version("prod-version-2", tag_names: %w[prod])
              .create_pact
          end

          let(:consumer_version_selectors) { Selectors.new(pact_selector_1) }
          let(:pact_selector_1) { Selector.all_for_tag("prod") }

          subject { Repository.new.find_for_verification("Bar2", consumer_version_selectors) }

          it "returns all the versions with the specified tag" do
            expect(subject.size).to be 2
            expect(find_by_consumer_version_number("prod-version-1").selectors.collect(&:tag)).to eq %w[prod]
            expect(find_by_consumer_version_number("prod-version-2").selectors.collect(&:tag)).to eq %w[prod]
          end

          it "dedupes them to ensure that each pact version is only verified once" do
            td.create_consumer_version("prod-version-3", tag_names: %w[prod])
              .republish_same_pact
            expect(subject.size).to be 2
            expect(subject.collect(&:consumer_version_number).sort).to eq %w[prod-version-1 prod-version-3]
          end
        end

        context "when all versions with a given tag for a given consumer are requested" do
          before do
            td.create_pact_with_hierarchy("Foo2", "prod-version-1", "Bar2")
              .create_consumer_version_tag("prod")
              .create_consumer_version("not-prod-version", tag_names: %w[master])
              .create_pact
              .create_consumer_version("prod-version-2", tag_names: %w[prod])
              .create_pact
              .create_consumer("Foo3")
              .create_consumer_version("prod-version-3", tag_names: %w[prod])
              .create_pact
          end

          let(:consumer_version_selectors) { Selectors.new(pact_selector_1) }
          let(:pact_selector_1) { Selector.all_for_tag_and_consumer("prod", "Foo2") }

          subject { Repository.new.find_for_verification("Bar2", consumer_version_selectors) }

          it "returns all the versions with the specified tag and consumer" do
            expect(subject.size).to be 2
            expect(find_by_consumer_version_number("prod-version-1")).to_not be nil
            expect(find_by_consumer_version_number("prod-version-2")).to_not be nil
            expect(find_by_consumer_version_number("prod-version-3")).to be nil
          end

          it "sets the selectors" do
            expect(find_by_consumer_version_number("prod-version-1").selectors.first.tag).to eq "prod"
            expect(find_by_consumer_version_number("prod-version-1").selectors.first.consumer).to eq "Foo2"
          end
        end

        context "when a pact version has been selected by two different selectors" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer_version_tag("dev")
              .create_consumer_version_tag("prod")
          end

          let(:pact_selector_1) { Selector.all_for_tag("prod") }
          let(:pact_selector_2) { Selector.latest_for_tag("dev") }
          let(:consumer_version_selectors) { Selectors.new(pact_selector_1, pact_selector_2) }

          it "returns a single selected pact with multiple selectors" do
            expect(subject.size).to eq 1
            expect(subject.first.selectors.size).to eq 2
          end
        end

        context "when no selectors are specified" do
          before do
            td.create_pact_with_hierarchy("Foo", "foo-latest-prod-version", "Bar")
              .create_consumer_version_tag("prod")
              .create_consumer_version("not-latest-dev-version", tag_names: ["dev"])
              .comment("next pact not selected")
              .create_pact
              .create_consumer_version("foo-latest-dev-version", tag_names: ["dev"])
              .create_pact
              .create_consumer("Baz")
              .create_consumer_version("baz-latest-dev-version", tag_names: ["dev"])
              .create_pact
          end

          let(:consumer_version_selectors) { Selectors.new }

          it "returns the latest pact for each provider" do
            expect(find_by_consumer_version_number("foo-latest-dev-version")).to_not be nil
            expect(find_by_consumer_version_number("baz-latest-dev-version")).to_not be nil
            expect(subject.size).to eq 2
          end

          it "does not set the tag name" do
            expect(find_by_consumer_version_number("foo-latest-dev-version").selectors).to eq [ResolvedSelector.new({ latest: true, consumer: "Foo" }, PactBroker::Domain::Version.find(number: "foo-latest-dev-version"))]
            expect(find_by_consumer_version_number("foo-latest-dev-version").overall_latest?).to be true
          end
        end

        context "when two consumers have exactly the same json content" do
          before do
            td.create_consumer
              .create_provider("Bar")
              .create_consumer_version
              .create_pact(json_content: { interactions: ["foo"] }.to_json )
              .create_consumer
              .create_consumer_version
              .create_pact(json_content: { interactions: ["foo"] }.to_json )
          end

          let(:consumer_version_selectors) { Selectors.new }

          it "returns a pact for each consumer" do
            expect(subject.size).to eq 2
          end
        end
      end
    end
  end
end
