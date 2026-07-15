
module PactBroker
  module Deployments
    describe ReleasedVersionService do
      describe ".create_or_update" do
        before do
          td.create_environment("test")
            .create_consumer("foo")
            .create_consumer_version("1")
        end

        let(:version) { td.and_return(:consumer_version) }
        let(:environment) { td.and_return(:environment) }

        context "when the version is already currently released" do
          it "returns the existing released version object" do
            released_version_1 = ReleasedVersionService.create_or_update("1234", version, environment)
            released_version_2 = ReleasedVersionService.create_or_update("4321", version, environment)
            expect(released_version_1.uuid).to eq released_version_2.uuid
          end
        end

        context "when the version was previously released, but there was another version released in the meantime" do
          before do
            td.create_consumer_version("2")
          end

          let(:version_1) { PactBroker::Domain::Version.order(:id).first }
          let(:version_2) { PactBroker::Domain::Version.order(:id).last }

          it "returns the same released version object" do
            released_version_1 = ReleasedVersionService.create_or_update("1234", version_1, environment)
            ReleasedVersionService.create_or_update("4321", version_2, environment)
            released_version_3 = ReleasedVersionService.create_or_update("4545", version_1, environment)
            expect(released_version_1.uuid).to eq released_version_3.uuid
          end
        end

        context "with an event listener" do
          before do
            allow(listener).to receive(:released_version_created)
          end

          let(:listener) { double("listener") }

          it "broadcasts an event with the released_version in the params (used by pf)" do
            expect(listener).to receive(:released_version_created) do | params |
              expect(params[:released_version].environment).to_not be nil
              expect(params[:released_version].version).to_not be nil
              expect(params[:released_version].pacticipant).to_not be nil
            end

            PactBroker::Events.subscribe(listener) do
              ReleasedVersionService.create_or_update("1234", version, environment)
            end
          end
        end
      end

      describe ".find_released_versions_for_version" do
        before do
          td.create_environment("test")
            .create_environment("prod")
            .create_consumer("foo")
            .create_consumer_version("1")
            .create_released_version_for_consumer_version(environment_name: "test")
            .create_released_version_for_consumer_version(environment_name: "prod")
            .create_consumer_version("2")
            .create_released_version_for_consumer_version(environment_name: "test")
        end

        let(:version) { PactBroker::Domain::Version.where(number: "1").single_record }

        it "returns all the released versions for the given version, with the environment eager loaded" do
          released_versions = ReleasedVersionService.find_released_versions_for_version(version)
          expect(released_versions.size).to eq 2
          expect(released_versions.collect { |rv| rv.environment.name }).to contain_exactly("test", "prod")
        end
      end

      describe ".find_released_versions_for_versions" do
        before do
          td.create_environment("test")
            .create_consumer("foo")
            .create_consumer_version("1")
            .create_released_version_for_consumer_version(environment_name: "test")
            .create_consumer_version("2")
            .create_released_version_for_consumer_version(environment_name: "test")
        end

        let(:version_1) { PactBroker::Domain::Version.where(number: "1").single_record }
        let(:version_2) { PactBroker::Domain::Version.where(number: "2").single_record }

        it "returns a hash of released versions grouped by version_id" do
          released_versions = ReleasedVersionService.find_released_versions_for_versions([version_1, version_2])
          expect(released_versions).to be_a(Hash)
          expect(released_versions[version_1.id].size).to eq 1
          expect(released_versions[version_2.id].size).to eq 1
        end
      end
    end
  end
end
