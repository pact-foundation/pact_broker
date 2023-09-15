require "pact_broker/domain/version"
require "pact_broker/db/clean/selector"

module PactBroker
  module Domain
    describe Version do
      describe "for_selector" do
        subject { Version.for_selector(selector).all }

        def find_version(number)
          subject.find{ |v| v.number == number }
        end

        def version_numbers
          subject.collect(&:number).sort_by(&:to_i)
        end

        context "when selecting the latest prod versions without a pacticipant name" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", tag_names: %w{prod})
              .create_consumer_version("2", tag_names: %w{prod})
              .create_consumer("Bar")
              .create_consumer_version("10", tag_names: %w{prod})
              .create_consumer_version("11", tag_names: %w{prod})
          end

          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: "prod", latest: true) }

          it "returns the latest prod version for each pacticipant" do
            expect(version_numbers).to eq %w{2 11}
          end
        end

        context "when selecting the latest prod versions with a pacticipant name" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", tag_names: %w{prod})
              .create_consumer_version("2", tag_names: %w{prod})
              .create_consumer("Bar")
              .create_consumer_version("10", tag_names: %w{prod})
              .create_consumer_version("11", tag_names: %w{prod})
          end

          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "Foo", tag: "prod", latest: true) }


          it "returns the latest prod version for Foo" do
            expect(version_numbers).to eq %w{2}
          end
        end

        context "when selecting all prod versions without a pacticipant name" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", tag_names: %w{prod})
              .create_consumer_version("2", tag_names: %w{prod})
              .create_consumer("Bar")
              .create_consumer_version("10", tag_names: %w{prod})
              .create_consumer_version("11", tag_names: %w{prod master})
              .create_consumer_version("12", tag_names: %w{master})
          end

          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: "prod") }

          it "selects all the production versions without a pacticipant name" do
            expect(version_numbers).to eq %w{1 2 10 11}
          end
        end

        context "when selecting the latest version for each tag (head versions)" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", tag_names: %w{prod})
              .create_consumer_version("2", tag_names: %w{prod}).comment("yes")
              .create_consumer_version("3", tag_names: %w{master})
              .create_consumer_version("4", tag_names: %w{master}).comment("yes")
              .create_consumer("Bar")
              .create_consumer_version("10", tag_names: %w{prod})
              .create_consumer_version("11", tag_names: %w{prod}).comment("yes")
          end

          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: true, latest: true) }

          it "selects the head versions for each tag" do
            expect(version_numbers).to eq %w{2 4 11}
          end

          context "when also specifying pacticipant name" do
            let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: true, latest: true, pacticipant_name: "Foo") }

            it "selects the head versions for each tag for the given pacticipant" do
              expect(version_numbers).to eq %w{2 4}
            end
          end
        end

        context "when selecting all tagged versions" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", tag_names: %w{prod})
              .create_consumer_version("2", tag_names: %w{prod})
              .create_consumer_version("4", tag_names: %w{master})
              .create_consumer_version("5")
              .create_consumer("Bar")
              .create_consumer_version("10", tag_names: %w{prod})
              .create_consumer_version("11")
          end

          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: true) }

          it "selects every version with a tag" do
            expect(version_numbers).to eq %w{1 2 4 10}
          end

          context "when also specifying pacticipant name" do
            let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: true, pacticipant_name: "Foo") }

            it "selects every version with a tag for the given pacticipant" do
              expect(version_numbers).to eq %w{1 2 4}
            end
          end
        end

        context "when selecting all versions for a tag with max age" do
          before do
            td.set_now(four_days_ago)
              .create_consumer("Foo")
              .create_consumer_version("1", tag_names: %w{master})
              .add_days(1)
              .create_consumer_version("2", tag_names: %w{master})
              .create_consumer_version("3", tag_names: %w{master})
          end

          let(:selector) { PactBroker::DB::Clean::Selector.new(tag: "master", max_age: max_age) }

          let(:max_age) { 3 }
          let(:four_days_ago) { Date.today - 4 }

          it "selects the consumer versions younger than the max age" do
            expect(version_numbers).to eq %w{2 3}
          end
        end

        context "when selecting the latest version for each branch" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", branch: "main")
              .create_consumer_version("2", branch: "main")
              .create_consumer("Bar")
              .create_consumer_version("3", branch: "main")
          end

          let(:selector) { PactBroker::DB::Clean::Selector.new(branch: true, latest: true) }

          it "selects the consumer versions that are the latest for their branches" do
            expect(version_numbers).to eq %w{2 3}
          end
        end

        context "when selecting all versions that are the latest from a branch" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("0", branch: "main")
              .create_consumer_version("1", branch: "main")
              .create_consumer_version("1", branch: "feat/x")
              .create_consumer_version("2")
              .create_consumer("Bar")
              .create_consumer_version("3", branch: "main")
              .create_consumer_version("4", branch: "main")
          end

          let(:selector) { PactBroker::DB::Clean::Selector.new(branch: true, latest: true) }

          it "selects the consumer versions that are the latest for their branches, but does not specify which branch they belong to, as it might be multiple, and we don't want a version row for each branch" do
            expect(version_numbers).to eq %w{1 4}
            expect(subject.collect{ |v| v.values[:branch_name] }).to eq [nil, nil]
          end
        end

        context "when selecting the latest versions from the main branches" do
          before do
            td.create_consumer("Foo", main_branch: "main")
              .create_consumer_version("1", branch: "main")
              .create_consumer_version("2", branch: "main")
              .create_consumer_version("3", branch: "not-main")
              .create_consumer("Bar", main_branch: "develop")
              .create_consumer_version("4", branch: "develop")
              .create_consumer_version("5", branch: "develop")
              .create_consumer_version("6", branch: "main")
          end

          let(:selector) { PactBroker::DB::Clean::Selector.new(main_branch: true, latest: true) }

          it "selects the versions that are the latest for their branches" do
            expect(version_numbers).to eq %w{2 5}
            expect(subject.find{ |v| v.pacticipant.name == "Bar" }.values[:branch_name]).to eq "develop"
            expect(subject.find{ |v| v.pacticipant.name == "Foo" }.values[:branch_name]).to eq "main"
          end
        end

        context "when selecting all versions from the main branches" do
          before do
            td.create_consumer("Foo", main_branch: "main")
              .create_consumer_version("1", branch: "main")
              .create_consumer_version("2", branch: "main")
              .create_consumer_version("3", branch: "not-main")
              .create_consumer("Bar", main_branch: "develop")
              .create_consumer_version("4", branch: "develop")
              .create_consumer_version("5", branch: "develop")
              .create_consumer_version("6", branch: "main")
          end

          let(:selector) { PactBroker::DB::Clean::Selector.new(main_branch: true) }

          it "selects the versions for the main branches" do
            expect(version_numbers).to eq %w{1 2 4 5}
            expect(subject.select{ |v| v.pacticipant.name == "Bar" }.collect{ |v| v.values[:branch_name] }.uniq).to eq ["develop"]
            expect(subject.select{ |v| v.pacticipant.name == "Foo" }.collect{ |v| v.values[:branch_name] }.uniq).to eq ["main"]
          end
        end

        context "when selecting all versions of a pacticipant currently deployed to an environment" do
          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(environment_name: "prod", pacticipant_name: "Foo") }

          before do
            td.create_environment("test")
              .create_consumer("Foo")
              .create_consumer_version("1")
              .create_deployed_version_for_consumer_version(target: "1")
              .create_consumer_version("2")
              .create_environment("prod")
              .create_deployed_version_for_consumer_version(target: "2")
              .create_consumer_version("3")
              .create_deployed_version_for_consumer_version(target: "3")
              .create_consumer_version("4")
              .create_deployed_version_for_consumer_version(currently_deployed: false)
              .create_consumer_version("5")
              .create_consumer("Bar")
              .create_consumer_version("10")
              .create_consumer_version("11")
          end

          it "returns the versions of that pacticipant currently deployed to the environment" do
            expect(version_numbers).to eq %w{2 3}
          end
        end

        context "when selecting all versions currently in an environment" do
          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(environment_name: "prod") }

          before do
            td.create_environment("test")
              .create_consumer("Foo")
              .create_consumer_version("1")
              .create_deployed_version_for_consumer_version(target: "1")
              .create_consumer_version("2")
              .create_environment("prod")
              .create_deployed_version_for_consumer_version(target: "2")
              .create_consumer_version("3")
              .create_consumer_version("5")
              .create_consumer("Bar")
              .create_consumer_version("10")
              .create_deployed_version_for_consumer_version(target: "3")
              .create_consumer_version("11")
              .create_deployed_version_for_consumer_version(currently_deployed: false)
              .create_consumer_version("12")
              .create_released_version_for_consumer_version
          end

          it "returns the versions of that pacticipant currently deployed to the environment" do
            expect(version_numbers).to eq %w{2 10 12}
          end
        end

        context "when selecting all currently deployed versions" do
          let(:selector) { PactBroker::DB::Clean::Selector.new(deployed: true) }

          before do
            td.create_environment("test")
              .create_consumer("Foo")
              .create_consumer_version("1")
              .create_deployed_version_for_consumer_version(target: "1")
              .create_consumer_version("2")
              .create_environment("prod")
              .create_deployed_version_for_consumer_version(target: "2")
              .create_consumer_version("3")
              .create_consumer_version("5")
              .create_consumer("Bar")
              .create_consumer_version("10")
              .create_deployed_version_for_consumer_version(target: "3")
              .create_consumer_version("11")
              .create_deployed_version_for_consumer_version(currently_deployed: false)
              .create_consumer_version("12")
              .create_released_version_for_consumer_version
          end

          it "returns the versions that are currently deployed" do
            expect(version_numbers).to eq %w{1 2 10}
          end
        end

        context "when selecting all currently released+supported versions" do
          let(:selector) { PactBroker::DB::Clean::Selector.new(released: true) }

          before do
            td.create_environment("test")
              .create_consumer("Foo")
              .create_consumer_version("1")
              .create_released_version_for_consumer_version
              .create_consumer_version("2")
              .create_environment("prod")
              .create_released_version_for_consumer_version
              .create_consumer_version("3")
              .create_consumer_version("5")
              .create_consumer("Bar")
              .create_consumer_version("10")
              .create_released_version_for_consumer_version
              .create_consumer_version("11")
              .create_released_version_for_consumer_version(currently_supported: false)
              .create_consumer_version("12")
              .create_deployed_version_for_consumer_version
          end

          it "returns the versions that are currently released+supported" do
            expect(version_numbers).to eq %w{1 2 10}
          end
        end

        context "selecting versions for a branch" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", branch: "main")
              .create_consumer_version("2", branch: "feat/foo")
              .create_consumer_version("3", branch: "main")
              .create_provider("Bar")
              .create_provider_version("10", branch: "main")
          end

          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(branch: "main") }

          it "returns the versions with the matching branch" do
            expect(version_numbers).to eq %w{1 3 10}
            expect(subject.first.values[:branch_name]).to eq "main"
          end
        end

        context "selecting latest version for a branch" do
          before do
            td.create_consumer("Foo")
              .create_consumer_version("1", branch: "main")
              .create_consumer_version("2", branch: "feat/foo")
              .create_consumer_version("3", branch: "main")
              .create_provider("Bar")
              .create_provider_version("10", branch: "main")
          end

          let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(branch: "main", latest: true) }

          it "returns the latest versions for each matching branch" do
            expect(version_numbers).to eq %w{3 10}
            expect(subject.first.values[:branch_name]).to eq "main"
          end
        end
      end

      describe "latest_for_pacticipant?" do
        before do
          td.create_consumer("Foo")
            .create_consumer_version("1")
            .create_consumer_version("2")
            .create_consumer("Bar")
            .create_consumer_version("5")
            .create_consumer_version("6")
            .create_consumer_version("7")
        end

        context "when the version is the latest for the pacticipant" do
          it "returns true" do
            expect(Version.for("Foo", "2").latest_for_pacticipant?).to be true
          end
        end

        context "when the version is not the latest version for the pacticipant" do
          it "returns false" do
            expect(Version.for("Foo", "1").latest_for_pacticipant?).to be false
          end
        end
      end

      describe "latest_version_for_pacticipant" do
        before do
          td.create_consumer("Foo")
            .create_consumer_version("1")
            .create_consumer_version("2")
            .create_consumer("Bar")
            .create_consumer_version("5")
            .create_consumer_version("6")
            .create_consumer_version("7")
        end

        subject { Version.order(:order) }

        it "lazy loads" do
          expect(subject.all[0].latest_version_for_pacticipant.number).to eq "2"
        end

        it "eager loads" do
          all = subject.eager(:latest_version_for_pacticipant).all
          expect(all[0].associations[:latest_version_for_pacticipant]).to_not be nil
          expect(all[0].latest_version_for_pacticipant.number).to eq "2"
        end
      end

      describe "#latest_pact_publication" do
        let!(:pact) do
          td
            .create_consumer
            .create_provider
            .create_consumer_version
            .create_pact
            .revise_pact
            .and_return(:pact)
        end
        let(:version) { Version.order(:id).last }

        it "returns the latest pact revision for the consumer version" do
          expect(version.latest_pact_publication.id).to eq pact.id
        end
      end

      describe "uq_ver_ppt_ord" do
        let(:consumer) do
          td
            .create_consumer
            .and_return(:consumer)
        end

        it "does not allow two versions with the same pacticipant and order" do
          Sequel::Model.db[:versions].insert(number: "1", order: 0, pacticipant_id: consumer.id, created_at: DateTime.new(2017), updated_at: DateTime.new(2017))
          expect { Sequel::Model.db[:versions].insert(number: "2", order: 0, pacticipant_id: consumer.id, created_at: DateTime.new(2017), updated_at: DateTime.new(2017)) }
            .to raise_error(Sequel::UniqueConstraintViolation)
        end
      end

      describe "latest_for_branch?" do
        before do
          td.create_consumer("Foo")
            .create_consumer_version("1", branch: "main")
            .create_consumer_version("2", branch: "main")
            .create_consumer_version("3", branch: nil)
        end

        subject { version.latest_for_branch? }

        context "when there is a later version with the same branch name" do
          let(:version) { Version.for("Foo", "1") }

          it { is_expected.to be false }
        end

        context "when there is a later version with the same branch name" do
          let(:version) { Version.for("Foo", "2") }

          it { is_expected.to be true }
        end

        context "when there is no branch" do
          let(:version) { Version.for("Foo", "3") }

          it { is_expected.to be false }
        end
      end

      describe "current_deployed_versions" do
        before do
          td.create_environment("test")
            .create_environment("prod")
            .create_consumer("Foo")
            .create_consumer_version("1")
            .create_deployed_version_for_consumer_version(currently_deployed: false, environment_name: "test")
            .create_deployed_version_for_consumer_version(currently_deployed: true, environment_name: "prod", target: "1")
            .create_consumer_version("2")
            .create_deployed_version_for_consumer_version(currently_deployed: true, environment_name: "prod", target: "2")
        end

        it "returns the currently active deployed versions" do
          expect(td.find_version("Foo", "1").current_deployed_versions.size).to eq 1
          expect(td.find_version("Foo", "1").current_deployed_versions.first.environment.name).to eq "prod"
        end

        it "eager loads" do
          all = PactBroker::Domain::Version.where(number: "2").eager(:current_deployed_versions).all
          expect(all.first.associations[:current_deployed_versions].size).to eq 1
          expect(all.first.associations[:current_deployed_versions].first.environment.name).to eq "prod"
        end
      end
    end
  end
end
