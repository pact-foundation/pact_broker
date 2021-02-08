require 'pact_broker/pacts/pact_publication'

module PactBroker
  module Pacts
    describe PactPublication do
      describe "to_domain" do
        before do
          td.create_pact_with_verification("Foo", "1", "Bar", "2")
        end

        subject { PactPublication.first.to_domain }

        its(:latest_verification) { is_expected.to_not be nil }
      end

      describe "to_domain_lightweight" do
        before do
          td.create_pact_with_verification("Foo", "1", "Bar", "2")
        end

        subject { PactPublication.first.to_domain_lightweight }

        it "raises an error if you try to access the latest_verification" do
          expect { subject.latest_verification }.to raise_error PactBroker::UnsetAttributeError
        end
      end

      describe "save and upsert" do
        before do
          td.create_consumer
            .create_provider
            .create_consumer_version
            .create_pact
        end

        let(:params) do
          {
            consumer_id: td.consumer.id,
            provider_id: td.provider.id,
            consumer_version_id: td.consumer_version.id,
            pact_version_id: PactVersion.first.id,
            revision_number: 1
          }
        end

        let(:pact_publication) do
          PactPublication.new(params)
        end

        context "when using a PactPublication with the same provider/consumer version/revision number as an existing PactPublication" do
          describe "save" do
            it "raises a constraint exception" do
              expect { pact_publication.save }.to raise_error Sequel::UniqueConstraintViolation
            end
          end

          describe "upsert" do
            it "does not raise an error" do
              pact_publication.upsert
            end

            it "sets the relationship objects" do
              pact_publication.upsert
              expect(pact_publication.id).to_not be nil
              expect(pact_publication.consumer.id).to eq td.consumer.id
              expect(pact_publication.consumer.name).to eq td.consumer.name
            end

            context "with objects instead of ids" do
              let(:params) do
                {
                  consumer: td.consumer,
                  provider: td.provider,
                  consumer_version: td.consumer_version,
                  pact_version: PactVersion.first,
                  revision_number: 1
                }
              end

              it "also works" do
                pact_publication.upsert
                expect(pact_publication.consumer_id).to eq td.consumer.id
              end
            end
          end
        end
      end

      describe "latest_for_branch?" do
        before do
          td.create_consumer("Foo")
            .create_provider("Bar")
            .create_consumer_version("1", branch: "main")
            .create_pact
            .create_consumer_version("2", branch: "main")
            .create_pact
            .create_consumer_version("3", branch: "main")
        end

        subject { pact_publication.latest_for_branch? }

        context "when there are no later pacts with the same branch" do
          let(:pact_publication) { PactPublication.where(consumer_version: td.find_version("Foo", "2")).single_record }

          it { is_expected.to be true }
        end

        context "when there are later pacts with the same branch" do
          let(:pact_publication) { PactPublication.where(consumer_version: td.find_version("Foo", "1")).single_record }

          it { is_expected.to be false }
        end
      end

      describe "#consumer_version_tags" do
        before do
          td.create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
            .create_consumer_version_tag("no")
            .create_consumer_version("3.4.5")
            .create_consumer_version_tag("yes")
            .create_pact
            .create_consumer_version("5.6.7")
            .create_consumer_version_tag("no")
        end

        let(:pact_publication) { PactPublication.find(id: td.pact.id) }

        it "" do
          expect(pact_publication.consumer_version_tags.collect(&:name)).to eq ["yes"]
        end
      end

      describe "#head_tag_names" do
        before do
          td.create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
            .create_consumer_version_tag("no")
            .create_consumer_version("3.4.5")
            .create_consumer_version_tag("yes")
            .create_pact
            .create_consumer_version("5.6.7")
            .create_consumer_version_tag("no")
            .create_consumer("Foo2")
            .create_consumer_version("3.4.5")
            .create_consumer_version_tag("yes", comment: "actually no, just here to make sure it selects the right one")
        end

        let(:pact_publication) { PactPublication.find(id: td.pact.id) }

        context "when the pact is the latest for a tag" do
          it "returns the relevant tag names" do
            expect(pact_publication.head_tag_names).to eq ["yes"]
            expect(pact_publication.head_pact_tags.collect(&:name)).to eq ["yes"]
          end
        end

        context "when the pact is not the latest for a tag" do
          it "returns the relevant tag names" do
            expect(pact_publication.head_tag_names).to eq ["yes"]
            expect(pact_publication.head_pact_tags.collect(&:name)).to eq ["yes"]
          end
        end
      end

      describe "created_after" do
        before do
          td.set_now(Date.new(2020, 1, 1))
            .create_consumer("Foo")
            .create_provider("Bar")
            .create_consumer_version("1", branch: "main")
            .create_pact
            .set_now(Date.new(2020, 1, 3))
            .create_consumer_version("2", branch: "feat/x")
            .create_pact
        end

        subject { PactPublication.created_after(Date.new(2020, 1, 2)).all }

        its(:size) { is_expected.to eq 1 }

        it "returns the pact publications created after the specified date" do
          expect(subject.first.consumer_version.number).to eq "2"
        end
      end

      describe "latest_by_consumer_branch" do
        before do
          td.set_now(Date.new(2020, 1, 1))
            .create_consumer("Foo")
            .create_provider("Bar")
            .create_consumer_version("1", branch: "main")
            .create_pact
            .set_now(Date.new(2020, 1, 2))
            .create_consumer_version("2", branch: "feat/x")
            .create_pact
            .set_now(Date.new(2020, 1, 3))
            .create_consumer_version("3", branch: "main", comment: "latest")
            .create_pact
            .set_now(Date.new(2020, 1, 4))
            .create_consumer_version("4", branch: "feat/x", comment: "latest")
            .create_pact
            .set_now(Date.new(2020, 1, 5))
            .create_consumer("FooZ")
            .create_consumer_version("6", branch: "main", comment: "latest, different consumer")
            .create_pact
            .set_now(Date.new(2020, 1, 6))
            .create_consumer_version("7", comment: "No branch")
            .create_pact
            .set_now(Date.new(2020, 1, 7))
            .create_consumer_version("8", branch: "main", comment: "No pact")
        end

        subject { PactPublication.latest_by_consumer_branch.all }

        let(:foo) { PactBroker::Domain::Pacticipant.where(name: "Foo").single_record }
        let(:bar) { PactBroker::Domain::Pacticipant.where(name: "Bar").single_record }
        let(:foo_z) { PactBroker::Domain::Pacticipant.where(name: "FooZ").single_record }

        it "returns the latest pact publications for each consumer/branch" do
          expect(subject.size).to eq 3
          hashes = subject.collect(&:values)

          expect(subject.find { |pp| pp.consumer_id == foo.id && pp[:branch] == "main" }.consumer_version.number).to eq "3"
          expect(subject.find { |pp| pp.consumer_id == foo.id && pp[:branch] == "feat/x" }.consumer_version.number).to eq "4"
          expect(subject.find { |pp| pp.consumer_id == foo_z.id && pp[:branch] == "main" }.consumer_version.number).to eq "6"
        end

        context "chained with created after" do
          subject { PactPublication.created_after(DateTime.new(2020, 1, 3)).latest_by_consumer_branch.all }

          its(:size) { is_expected.to eq 2 }

          it "returns the right versions" do
            expect(subject.find { |pp| pp.consumer_id == foo.id && pp[:branch] == "feat/x" }.consumer_version.number).to eq "4"
            expect(subject.find { |pp| pp.consumer_id == foo_z.id && pp[:branch] == "main" }.consumer_version.number).to eq "6"
          end
        end
      end

      describe "latest_for_consumer_branch" do
        before do
          td.create_consumer("Foo")
            .create_provider("Bar")
            .create_consumer_version("1", branch: "main")
            .create_pact
            .create_consumer_version("2", branch: "main")
            .create_pact
            .create_consumer_version("3", branch: "feat-x")
            .create_pact
            .create_consumer("Foo2")
            .create_provider("Bar2")
            .create_consumer_version("10", branch: "main")
            .create_pact
            .create_consumer_version("11", branch: "main")
            .create_pact
        end

        subject { PactPublication.latest_for_consumer_branch("main") }

        it "returns the latest pacts for the branches with the specified name (for any consumer/provider)" do
          all = subject.all.sort_by{ |pact_publication| pact_publication.consumer_version.order }
          expect(all.size).to eq 2
          expect(all.first.consumer.name).to eq "Foo"
          expect(all.first.provider.name).to eq "Bar"
          expect(all.first.consumer_version.number).to eq "2"

          expect(all.last.consumer.name).to eq "Foo2"
          expect(all.last.provider.name).to eq "Bar2"
          expect(all.last.consumer_version.number).to eq "11"
        end

        context "when chained" do
          it "works" do
            all = PactPublication.for_provider(td.find_pacticipant("Bar")).latest_for_consumer_branch("main").all
            expect(all.first.provider.name).to eq "Bar"
          end
        end
      end

      describe "latest_by_consumer_tag" do
        before do
          td.create_consumer("Foo")
            .create_provider("Bar")
            .create_consumer_version("1", tag_names: ["main"])
            .create_pact
            .create_consumer_version("2", tag_names: ["feat/x"])
            .create_pact
            .create_consumer_version("3", tag_names: ["main"], comment: "latest")
            .create_pact
            .create_consumer_version("4", tag_names: ["feat/x"], comment: "latest")
            .create_pact
            .create_consumer("FooZ")
            .create_consumer_version("6", tag_names: ["main"], comment: "Different consumer")
            .create_pact
            .create_consumer_version("7", comment: "No branch")
            .create_pact
            .create_consumer_version("8", tag_names: ["main"], comment: "No pact")
        end

        subject { PactPublication.latest_by_consumer_tag.all }

        let(:foo) { PactBroker::Domain::Pacticipant.where(name: "Foo").single_record }
        let(:bar) { PactBroker::Domain::Pacticipant.where(name: "Bar").single_record }
        let(:foo_z) { PactBroker::Domain::Pacticipant.where(name: "FooZ").single_record }

        it "returns the latest pact publications for each consumer/branch" do
          expect(subject.size).to eq 3
          hashes = subject.collect(&:values)

          expect(subject.find { |pp| pp.consumer_id == foo.id && pp[:tag_name] == "main" }.consumer_version.number).to eq "3"
          expect(subject.find { |pp| pp.consumer_id == foo.id && pp[:tag_name] == "feat/x" }.consumer_version.number).to eq "4"
          expect(subject.find { |pp| pp.consumer_id == foo_z.id && pp[:tag_name] == "main" }.consumer_version.number).to eq "6"
        end
      end

      describe "overall_latest" do
        before do
          td.create_consumer("Foo")
            .create_provider("Bar")
            .create_consumer_version("1", tag_names: ["main"])
            .create_pact
            .create_consumer_version("2", tag_names: ["main"])
            .create_pact
            .create_consumer_version("3", tag_names: ["feat/x"])
            .create_pact
            .create_consumer("Foo2")
            .create_provider("Bar2")
            .create_consumer_version("10", tag_names: ["main"])
            .create_pact
            .create_consumer_version("11", tag_names: ["main"])
            .create_pact
        end

        subject { PactPublication.overall_latest }

        it "returns the latest by consumer/provider" do
          all = subject.all.sort_by{ | pact_publication | pact_publication.consumer_version.order }
          expect(all.size).to eq 2
        end

        context "when chained" do
          it "works with a consumer" do
            expect(PactPublication.for_consumer(td.find_pacticipant("Foo")).overall_latest.all.first.consumer.name).to eq "Foo"
          end

          it "works with a consumer and provider" do
            td.create_pact_with_hierarchy("Foo", "666", "Nope")
            all = PactPublication
              .for_consumer(td.find_pacticipant("Foo"))
              .for_provider(td.find_pacticipant("Bar"))
              .overall_latest.all
            expect(all.size).to eq 1
            expect(all.first.consumer.name).to eq "Foo"
            expect(all.first.provider.name).to eq "Bar"
          end
        end
      end

      describe "latest_for_consumer_tag" do
        before do
          td.create_consumer("Foo")
            .create_provider("Bar")
            .create_consumer_version("1", tag_names: ["main"])
            .create_pact
            .create_consumer_version("2", tag_names: ["main"])
            .create_pact
            .create_consumer_version("3", tag_names: ["feat/x"])
            .create_pact
            .create_consumer("Foo2")
            .create_provider("Bar2")
            .create_consumer_version("10", tag_names: ["main"])
            .create_pact
            .create_consumer_version("11", tag_names: ["main"])
            .create_pact
        end

        subject { PactPublication.latest_for_consumer_tag("main") }

        it "returns the latest pacts for the tags with the specified name (for any consumer/provider)" do
          all = subject.all.sort_by{ |pact_publication| pact_publication.consumer_version.order }
          expect(all.size).to eq 2
          expect(all.first.consumer.name).to eq "Foo"
          expect(all.first.provider.name).to eq "Bar"
          expect(all.first.consumer_version.number).to eq "2"

          expect(all.last.consumer.name).to eq "Foo2"
          expect(all.last.provider.name).to eq "Bar2"
          expect(all.last.consumer_version.number).to eq "11"
        end

        context "when chained" do
          it "works" do
            all = PactPublication.for_provider(td.find_pacticipant("Bar")).latest_for_consumer_tag("main").all
            expect(all.first.provider.name).to eq "Bar"
          end
        end
      end

      describe "#successfully_verified_by_provider_branch" do
        let(:bar) { td.find_pacticipant("Bar") }

        subject { PactPublication.successfully_verified_by_provider_branch(bar.id, "main").all }

        context "PactPublication" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_verification(provider_version: "2", branch: "main", success: false)
              .create_pact_with_hierarchy("Foo", "2", "Bar")
              .create_verification(provider_version: "2", branch: "main", success: true)
              .create_pact_with_hierarchy("Foo", "3", "Bar")
              .create_verification(provider_version: "3", branch: "not-main", success: true)
          end

          it "returns the pact publications that have been succesfully verified by the given provider id and branch" do
            expect(subject.size).to eq 1
            expect(subject.first.consumer_version.number).to eq "2"
          end
        end


        context "with chained scopes" do
          subject { PactPublication.latest_by_consumer_branch.successfully_verified_by_provider_branch(bar.id, "provider-main").all }

          context "when there are no latest branch pacts that have been successfully verified by the specified provider branch" do
            before do
              td.create_consumer("Foo")
                .create_provider("Bar")
                .create_consumer_version("1", branch: "main", comment: "not latest")
                .create_pact
                .create_verification(provider_version: "1", success: true, branch: "provider-main", comment: "successful but not latest")
                .create_consumer_version("2", branch: "main", comment: "latest")
                .create_pact
                .create_verification(provider_version: "2", success: false, branch: "provider-main", comment: "latest but not successful")
                .create_consumer_version("3", branch: "feat/x", comment: "latest")
                .create_pact
                .create_verification(provider_version: "3", success: true, branch: "not-provider-main", comment: "latest, successful, but wrong branch")
            end

            it { is_expected.to eq [] }
          end

          context "when there are latest branch pacts that have been successfully verified by the specified provider branch" do
            before do
              td.create_consumer("Foo")
                .create_provider("Bar")
                .create_consumer_version("1", branch: "main", comment: "not latest")
                .create_pact
                .create_verification(provider_version: "1", success: true, branch: "provider-main")
                .create_consumer_version("2", branch: "main", comment: "latest")
                .create_pact
                .create_verification(provider_version: "1", success: true, branch: "provider-main")
                .create_verification(provider_version: "2", success: true, branch: "provider-main", number: "2")
            end

            its(:size) { is_expected.to eq 1 }

            it "returns them" do
              expect(subject.first.consumer_version.number).to eq "2"
            end
          end

          context "when there are latest tagged pacts that have been successfully verified by the specified provider branch" do
            before do
              td.create_consumer("Foo")
                .create_provider("Bar")
                .create_consumer_version("1", tag_names: ["main"], comment: "not latest")
                .create_pact
                .create_verification(provider_version: "1", success: true, tag_names: ["provider-main"])
                .create_consumer_version("2", tag_names: ["main"], comment: "latest")
                .create_pact
                .create_verification(provider_version: "1", success: true, branch: "provider-main")
                .create_verification(provider_version: "2", success: true, branch: "provider-main", number: "2")
            end

            subject { PactPublication.latest_by_consumer_tag.successfully_verified_by_provider_branch(bar.id, "provider-main").all }

            its(:size) { is_expected.to eq 1 }

            it "returns them" do
              expect(subject.first.consumer_version.number).to eq "2"
            end
          end

          context "subtracting Pact Publications" do
            before do
              td.create_consumer("Foo")
                .create_provider("Bar")
                .create_consumer_version("1", branch: "main", tag_names: ["main"], comment: "not latest")
                .create_pact
                .create_verification(provider_version: "1", success: true, branch: "provider-main")
                .create_consumer_version("2", branch: "main", tag_names: ["main"], comment: "latest")
                .create_pact
                .create_verification(provider_version: "1", success: true, branch: "provider-main")
                .create_verification(provider_version: "2", success: true, branch: "provider-main", number: "2")
                .create_consumer_version("3", branch: "feat/x", tag_names: ["feat/x"], )
                .create_pact
            end

            let(:bar) { td.find_pacticipant("Bar") }

            it "with branches" do
              potential = PactPublication.for_provider(bar).latest_by_consumer_branch
              already_verified = potential.successfully_verified_by_provider_branch(bar.id, "provider-main")
              not_verified = potential.all - already_verified.all

              expect(not_verified.size).to eq 1
              expect(not_verified.first.consumer_version_number).to eq "3"
            end

            it "with tags" do
              potential = PactPublication.for_provider(bar).latest_by_consumer_tag
              already_verified = potential.successfully_verified_by_provider_branch(bar.id, "provider-main")
              not_verified = potential.all - already_verified.all

              expect(not_verified.size).to eq 1
              expect(not_verified.first.consumer_version_number).to eq "3"
            end
          end
        end
      end
    end
  end
end
