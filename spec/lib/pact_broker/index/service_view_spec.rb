require "pact_broker/index/service"

module PactBroker
  module Index
    describe Service do
      let(:tags) { ["prod", "production"] }
      let(:options) do
        {
          page_size: page_size,
          page_number: page_number,
          view: view,
          consumer_name: consumer_name,
          provider_name: provider_name
        }
      end
      let(:page_number) { nil }
      let(:page_size) { nil }
      let(:consumer_name) { "Foo"}
      let(:provider_name) { "Bar"}

      subject { Service.find_index_items(options) }

      describe "find_index_items" do
        context "when view == branch" do
          before do
            td.create_consumer("Foo")
              .create_provider("Bar")
              .create_consumer_version("1", branch: "main", tag_names: ["dev"])
              .create_pact
              .create_consumer_version("2", tag_names: ["dev"])
              .create_pact
              .create_consumer_version("3", branch: "feat/x", tag_names: ["dev-1"])
              .create_pact
              .create_consumer_version("4", branch: "main", tag_names: ["dev-2"])
              .create_pact
              .create_consumer_version("4", branch: "feat/y")
              .create_consumer("NotFoo")
              .create_consumer_version("10", branch: "main")
              .create_pact
          end

          let(:view) { "branch" }

          let(:consumer_version_numbers) { subject.collect(&:consumer_version_number) }

          it "returns the latest pacts for each branch" do
            expect(consumer_version_numbers).to eq ["4", "3"]
          end
        end

        context "when view == tag" do
          before do
            td.create_consumer("Foo")
              .create_provider("Bar")
              .create_consumer_version("1", branch: "main", tag_names: ["dev"])
              .create_pact
              .create_consumer_version("2", tag_names: ["dev"])
              .create_pact
              .create_consumer_version("3", branch: "feat/x", tag_names: ["dev-2"])
              .create_pact
              .create_consumer_version("4", branch: "main", tag_names: ["dev-3"])
              .create_pact
              .create_consumer_version("4", branch: "feat/y")
              .create_consumer("NotFoo")
              .create_consumer_version("10", branch: "main")
              .create_pact
          end

          let(:view) { "tag" }

          let(:consumer_version_numbers) { subject.collect(&:consumer_version_number) }

          it "returns the latest pacts for each tag" do
            expect(consumer_version_numbers).to eq ["4", "3", "2"]
          end
        end

        context "when view == environment" do
          before do
            td.create_environment("test")
              .create_consumer("Foo")
              .create_provider("Bar")
              .create_consumer_version("1")
              .create_pact
              .create_deployed_version_for_consumer_version(currently_deployed: false)
              .create_consumer_version("2")
              .create_pact
              .create_deployed_version_for_consumer_version
              .create_consumer_version("3")
              .create_pact
              .create_released_version_for_consumer_version(currently_supported: false)
              .create_consumer_version("4")
              .create_pact
              .create_released_version_for_consumer_version
              .create_consumer_version("5")
              .create_pact
          end

          let(:view) { "environment" }

          let(:consumer_version_numbers) { subject.collect(&:consumer_version_number) }

          it "returns the currently deployed and released+supported pacts" do
            expect(consumer_version_numbers).to eq ["4", "2"]
          end
        end

        context "when view == all" do
          before do
            td.create_environment("test")
              .create_consumer("Foo")
              .create_provider("Bar")
              .create_consumer_version("1")
              .create_pact
              .create_deployed_version_for_consumer_version
              .create_consumer_version("2")
              .create_pact
              .create_released_version_for_consumer_version
              .create_consumer_version("3", branch: "main")
              .create_pact
              .create_consumer_version("4", branch: "main")
              .create_pact
              .create_consumer_version("5", tag_names: "dev")
              .create_pact
              .create_consumer_version("6", tag_names: "dev")
              .create_pact
              .create_consumer_version("7")
              .create_pact
              .create_consumer_version("8")
              .create_pact
          end

          let(:view) { "all" }

          let(:consumer_version_numbers) { subject.collect(&:consumer_version_number) }

          it "returns the latest for each branch, tag, deployed, released + overall latest" do
            expect(consumer_version_numbers).to eq ["8", "6", "4", "2", "1"]
          end
        end
      end
    end
  end
end
