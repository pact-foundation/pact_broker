require 'pact_broker/pacts/repository'

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

        context "when currently_deployed is true" do
          before do
            td.create_environment("test")
              .create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_deployed_version_for_consumer_version(currently_deployed: false)
              .create_pact_with_hierarchy("Foo", "2", "Bar")
              .create_deployed_version_for_consumer_version(currently_deployed: true)
              .create_pact_with_hierarchy("Waffle", "3", "Bar")
              .create_pact_with_hierarchy("Waffle", "4", "Bar")
              .create_deployed_version_for_consumer_version(currently_deployed: true)
          end

          let(:consumer_version_selectors) do
            PactBroker::Pacts::Selectors.new(
              PactBroker::Pacts::Selector.for_currently_deployed
            )
          end

          it "returns the pacts for the currently deployed versions" do
            expect(subject.size).to eq 2
            expect(subject.first.selectors).to eq [PactBroker::Pacts::Selector.for_currently_deployed.resolve_for_environment(td.find_version("Foo", "2"), "test")]
            expect(subject.last.selectors).to eq [PactBroker::Pacts::Selector.for_currently_deployed.resolve_for_environment(td.find_version("Waffle", "4"), "test")]
          end
        end

        context "when currently_deployed is true and an environment is specified" do
          before do
            td.create_environment("test")
              .create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_deployed_version_for_consumer_version(currently_deployed: false)
              .create_pact_with_hierarchy("Foo", "2", "Bar")
              .create_deployed_version_for_consumer_version(currently_deployed: true)
              .create_pact_with_hierarchy("Waffle", "3", "Bar")
              .create_pact_with_hierarchy("Waffle", "4", "Bar")
              .create_deployed_version_for_consumer_version(currently_deployed: true)
              .create_environment("prod")
              .create_pact_with_hierarchy("Foo", "5", "Bar")
              .comment("not included, wrong environment")
              .create_deployed_version_for_consumer_version(currently_deployed: true)
          end

          let(:consumer_version_selectors) do
            PactBroker::Pacts::Selectors.new(
              PactBroker::Pacts::Selector.for_currently_deployed("test")
            )
          end

          it "returns the pacts for the currently deployed versions" do
            expect(subject.size).to eq 2
            expect(subject.first.selectors).to eq [PactBroker::Pacts::Selector.for_currently_deployed("test").resolve(td.find_version("Foo", "2"))]
            expect(subject.last.selectors).to eq [PactBroker::Pacts::Selector.for_currently_deployed("test").resolve(td.find_version("Waffle", "4"))]
          end
        end

        context "when the same version is deployed to multiple environments" do
          before do
            td.create_environment("test")
              .create_environment("prod")
              .create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_deployed_version_for_consumer_version(environment_name: "test")
              .create_deployed_version_for_consumer_version(environment_name: "prod")
          end

          let(:consumer_version_selectors) do
            PactBroker::Pacts::Selectors.new(
              PactBroker::Pacts::Selector.for_currently_deployed
            )
          end

          it "returns one pact_publication with multiple selectors" do
            expect(subject.size).to eq 1
            expect(subject.first.selectors.size).to eq 2
            expect(subject.first.selectors.first.environment).to eq "test"
            expect(subject.first.selectors.last.environment).to eq "prod"
          end
        end
      end
    end
  end
end
