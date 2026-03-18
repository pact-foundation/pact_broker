
module PactBroker
  module Pacts
    describe Repository do
      describe "find_wip_pact_versions_for_provider" do
        let(:provider_tags) { %w[dev] }
        let(:provider_version_branch) { nil }
        let(:options) { { include_wip_pacts_since: include_wip_pacts_since } }
        let(:include_wip_pacts_since) { (Date.today - 1).to_datetime }

        # Default to enabled unless explicitly testing legacy behavior
        before do
          allow(PactBroker.configuration).to receive(:dynamic_wip_window_enabled?).and_return(true)
        end

        subject { Repository.new.find_wip_pact_versions_for_provider("bar", provider_version_branch, provider_tags, [], options) }

        context "when there are no tags" do
          let(:provider_tags) { [] }

          it "returns an empty list" do
            expect(subject).to eq []
          end
        end

        context "when there are multiple wip pacts" do
          before do
            td.create_provider("bar")
              .create_provider_version("333", tag_names: provider_tags)
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-1")
              .add_day
              .create_consumer_version("2", branch: "branch-1")
              .create_pact
              .create_pact_with_hierarchy("meep", "2", "bar")
              .create_consumer_version_tag("feat-2")
              .add_day
              .create_pact_with_hierarchy("foo", "3", "bar")
              .create_consumer_version_tag("feat-2")
              .add_day
              .create_pact_with_hierarchy("meep", "1", "bar")
              .create_consumer_version_tag("feat-1")
          end

          let(:provider_tags) { %w[dev] }

          it "sorts them" do
            expect(subject[0].consumer_name).to eq "foo"
            expect(subject[0].consumer_version_number).to eq "1"

            expect(subject[1].consumer_name).to eq "foo"
            expect(subject[1].consumer_version_number).to eq "2"

            expect(subject[2].consumer_name).to eq "foo"
            expect(subject[2].consumer_version_number).to eq "3"

            expect(subject[3].consumer_name).to eq "meep"
            expect(subject[3].consumer_version_number).to eq "2"

            expect(subject[4].consumer_name).to eq "meep"
            expect(subject[4].consumer_version_number).to eq "1"
          end

          it "sets the selectors" do
            expect(subject[0].selectors).to contain_exactly(have_attributes(latest: true, tag: "feat-1", consumer_version: have_attributes(number: "1")))
            expect(subject[1].selectors).to contain_exactly(have_attributes(latest: true, branch: "branch-1", consumer_version: have_attributes(number: "2")))
            expect(subject[2].selectors).to contain_exactly(have_attributes(latest: true, tag: "feat-2", consumer_version: have_attributes(number: "3")))
            expect(subject[3].selectors).to contain_exactly(have_attributes(latest: true, tag: "feat-2", consumer_version: have_attributes(number: "2")))
            expect(subject[4].selectors).to contain_exactly(have_attributes(latest: true, tag: "feat-1", consumer_version: have_attributes(number: "1")))
          end
        end

        context "when there are multiple wip pacts with the same content" do
          before do
            td.create_provider("bar")
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar", json_content)
              .create_consumer_version_tag("feat-1")
              .add_day
              .create_pact_with_hierarchy("foo", "2", "bar", json_content)
              .create_consumer_version_tag("feat-2")
          end

          let(:json_content) { { "interactions" => ["foo"] }.to_json }
          let(:provider_tags) { %w[dev] }

          it "de-duplicates them" do
            expect(subject.size).to eq 1
          end

          it "merges the selectors" do
            expect(subject.first.selectors.size).to eq 2
            expect(subject.first.wip).to be true
          end
        end

        context "when the latest pact for a tag has been successfully verified by the given provider tag" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .comment("above not included because it's not the latest prod")
              .create_consumer_version("2")
              .create_consumer_version_tag("prod")
              .create_pact
              .create_verification(provider_version: "3", tag_names: %w[dev], comment: "not included because already verified")
          end

          let(:provider_tags) { %w[dev] }

          it "is not included" do
            expect(subject.size).to be 0
          end
        end

        context "when the latest pact for a tag has been successfully verified by the given provider tag but it was a WIP verification" do
          before do
            td.create_provider("bar")
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .comment("above not included because it's not the latest dev")
              .create_consumer_version("2")
              .create_consumer_version_tag("feat-1")
              .create_pact
              .create_verification(wip: true, success: true, provider_version: "3", tag_names: %w[dev])
          end

          let(:provider_tags) { %w[dev] }

          it "it is included" do
            expect(subject[0].consumer_name).to eq "foo"
            expect(subject[0].consumer_version_number).to eq "2"
          end
        end

        context "when the latest pact for a tag has been successfully verified by one of the given provider tags, but not the other" do
          before do
            td.create_provider("bar")
              .create_provider_version("44")
              .create_provider_version_tag("feat-1")
              .add_day
              .create_consumer("foo")
              .create_consumer_version("1")
              .create_pact
              .create_consumer_version_tag("prod")
              .create_verification(provider_version: "3", tag_names: %w[dev], comment: "not included because already verified")
          end

          let(:provider_tags) { %w[dev feat-1] }

          it "is included" do
            expect(subject.size).to be 1
          end

          it "sets the pending tags to the tag that has not yet been verified" do
            expect(subject.first.pending_provider_tags).to eq %w[feat-1]
          end
        end

        context "when the latest pact for a tag has failed verification from the specified provider version" do
          before do
            td.create_provider("bar")
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-1")
              .create_verification(provider_version: "3", success: false, tag_names: %[dev])
          end

          it "is included" do
            expect(subject.size).to be 1
          end

          it "sets the pending tags" do
            expect(subject.first.pending_provider_tags).to eq %w[dev]
          end
        end

        context "when there are no consumer tags" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_verification(provider_version: "3", success: false, tag_names: %[dev])
          end

          it "returns an empty list" do
            expect(subject).to eq []
          end
        end

        context "when the latest pact for a tag has successful and failed verifications" do
          before do
            td.create_provider("bar")
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("dev")
              .create_verification(provider_version: "3", success: true, tag_names: %[dev])
              .create_verification(provider_version: "5", success: false, number: 2, tag_names: %[dev])
          end

          it "is not included, but maybe it should be? can't really work out a scenario where this is likely to happen" do
            expect(subject).to eq []
          end
        end



        context "when the latest pact for a tag has not been verified" do
          before do
            td.create_provider("bar")
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-1")
          end

          it "is included" do
            expect(subject.size).to be 1
          end

          it "sets the pending tags" do
            expect(subject.first.pending_provider_tags).to eq %w[dev]
          end
        end

        context "when the provider name does not match the given provider name" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "baz")
              .create_provider("bar")
          end

          it "is not included" do
            expect(subject.size).to be 0
          end
        end

        context "when the pact was published before the specified include_wip_pacts_since" do
          before do
            # This test specifically validates legacy behavior where user input is honored
            # If dynamic window enabled, user input would be ignored
            allow(PactBroker.configuration).to receive(:dynamic_wip_window_enabled?).and_return(false)
            
            td.create_provider("bar")
              .create_provider_version("333")
              .create_provider_version_tag("dev")
              .add_day
              .create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("prod")
          end

          let(:include_wip_pacts_since) { (Date.today + 3).to_datetime }

          it "is not included" do
            expect(subject.size).to be 0
          end
        end

        context "when the provider tag does not exist yet and there are no provider versions" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-x")
          end

          it "is included" do
            expect(subject.size).to be 1
          end
        end

        context "when the provider tag does not exist yet but there are other provider versions" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-x")
              .create_provider_version("1")
          end

          it "is included" do
            expect(subject.size).to be 1
          end
        end

        context "when a pact was already successfully verified by another branch before the first creation of one tag but not the other" do
          let(:provider_tags) { %w[dev feat-1] }

          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-x")
              .add_day
              .create_verification(provider_version: "1", success: false, number: 1, tag_names: %w[dev])
              .add_day
              .create_verification(provider_version: "2", success: true, number: 2, tag_names: %w[blah])
              .add_day
              .create_verification(provider_version: "3", success: false, number: 3, tag_names: %w[feat-1])
          end

          it "is wip for the first tag but not the second" do
            expect(subject.first.pending_provider_tags).to eq %w[dev]
          end
        end

        context "when a pact was already successfully verified by another branch before the first creation of one tag but not the other" do
          let(:provider_tags) { %w[dev feat-1] }

          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("feat-x")
              .add_day
              .create_verification(provider_version: "1", success: true, number: 1, tag_names: %w[dev])
              .add_day
              .create_verification(provider_version: "3", success: false, number: 3, tag_names: %w[feat-1])
          end

          it "this should be WIP, as it hasn't been successfully verified by both dev AND feat-1 - need to update logic to exclude previous verifications from other specified tags. But two tags doesn't make sense anyway. Will leave it for now.", pending: true do
            expect(subject).to_not be_empty
          end
        end

        context "when the provider version tag specified does not exist yet and there are previous successful verifications from another branch" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("main")
              .create_verification(provider_version: "20", tag_names: ["dev"], success: true)
              .create_verification(provider_version: "21", number: 2)
          end

          let(:provider_tags) { %w[feat-new-branch] }

          it { is_expected.to be_empty }
        end

        context "when the provider version tag specified does not exist yet and there are previous failed verifications from another branch" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("main")
              .create_verification(provider_version: "20", tag_names: ["dev"], success: false)
              .create_verification(provider_version: "21", number: 2)
          end

          let(:provider_tags) { %w[feat-new-branch] }

          it "is included" do
            expect(subject.first.pending_provider_tags).to eq [provider_tags.first]
          end
        end

        context "when there is a successful verification from before the first provider version with the specified tag was created" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("main")
              .create_verification(provider_version: "20", tag_names: ["dev"], success: true)
              .add_day
              .create_verification(provider_version: "21", tag_names: ["feat-new-branch"], number: 2, success: false)
          end

          let(:provider_tags) { %w[feat-new-branch] }

          it { is_expected.to be_empty }
        end

        context "when there is a successful verification from after the first provider version with the specified tag was created" do
          before do
            td.create_pact_with_hierarchy("foo", "1", "bar")
              .create_consumer_version_tag("main")
              .create_verification(provider_version: "21", tag_names: ["feat-new-branch"], number: 2, success: false)
              .add_day
              .create_verification(provider_version: "20", tag_names: ["dev"], success: true)
          end

          let(:provider_tags) { %w[feat-new-branch] }

          it "is included" do
            expect(subject.first.pending_provider_tags).to eq [provider_tags.first]
          end
        end

        context "dynamic WIP window calculation" do
          context "when dynamic WIP window is enabled" do
            before do
              allow(PactBroker.configuration).to receive(:dynamic_wip_window_enabled?).and_return(true)
              
              td.create_provider("bar")
                .create_provider_version("333", tag_names: provider_tags)
                .create_pact_with_hierarchy("foo", "1", "bar")
                .create_consumer_version_tag("feat-1")
            end

            let(:include_wip_pacts_since) { (Date.today - 100).to_datetime }

            it "overrides user input with calculated window" do
              expect(subject.size).to eq 1
              expect(subject.first.consumer_name).to eq "foo"
            end

            context "when pact is outside calculated window" do
              before do
                # 20-day-old pact: outside calculated window (7-14 days), inside user input (100 days)
                td.subtract_days(20)
                  .create_pact_with_hierarchy("old-consumer", "1", "bar")
                  .create_consumer_version_tag("feat-1")
                td.add_days(20)
              end

              it "excludes old pact" do
                expect(subject.size).to eq 1
                expect(subject.first.consumer_name).to eq "foo"
              end
            end

            context "with failed verification" do
              before do
                td.create_verification(provider_version: "333", success: false)
              end

              it "includes as WIP" do
                expect(subject.size).to eq 1
              end
            end

            context "with successful verification" do
              before do
                td.create_verification(provider_version: "333", success: true)
              end

              it "excludes verified pact" do
                expect(subject.size).to eq 0
              end
            end

            context "with multiple consumers" do
              before do
                td.create_pact_with_hierarchy("consumer2", "1", "bar")
                  .create_consumer_version_tag("feat-1")
                  .create_pact_with_hierarchy("consumer3", "1", "bar")
                  .create_consumer_version_tag("feat-1")
              end

              it "includes all unverified pacts" do
                expect(subject.size).to eq 3
                expect(subject.map(&:consumer_name)).to match_array(["foo", "consumer2", "consumer3"])
              end
            end

            context "when P80 is below minimum" do
              before do
                # Create 5 pacts at 2-3 days old
                # P80 of [2,2,2,3,3] = 3 days → clamped to 7-day minimum
                td.subtract_days(2)
                  .create_pact_with_hierarchy("recent-0", "1", "bar")
                  .create_consumer_version_tag("feat-1")
                  .create_pact_with_hierarchy("recent-1", "1", "bar")
                  .create_consumer_version_tag("feat-1")
                  .create_pact_with_hierarchy("recent-2", "1", "bar")
                  .create_consumer_version_tag("feat-1")
                
                td.add_days(2)
                  .subtract_days(3)
                  .create_pact_with_hierarchy("recent-3", "1", "bar")
                  .create_consumer_version_tag("feat-1")
                  .create_pact_with_hierarchy("recent-4", "1", "bar")
                  .create_consumer_version_tag("feat-1")
                
                # 6-day-old: inside 7-day minimum window
                td.add_days(3)
                  .subtract_days(6)
                  .create_pact_with_hierarchy("six-day", "1", "bar")
                  .create_consumer_version_tag("feat-1")
                
                # 8-day-old: outside 7-day minimum window
                td.add_days(6)
                  .subtract_days(8)
                  .create_pact_with_hierarchy("eight-day", "1", "bar")
                  .create_consumer_version_tag("feat-1")
                td.add_days(8)
              end

              it "enforces 7-day minimum window" do
                consumer_names = subject.map(&:consumer_name)
                expect(consumer_names).to include("six-day")
                expect(consumer_names).not_to include("eight-day")
              end
            end
          end

          context "when dynamic WIP window is disabled" do
            before do
              allow(PactBroker.configuration).to receive(:dynamic_wip_window_enabled?).and_return(false)
            end

            context "with user date beyond 14 days" do
              before do
                td.create_provider("bar")
                  .create_provider_version("333", tag_names: provider_tags)
                  .create_pact_with_hierarchy("foo", "1", "bar")
                  .create_consumer_version_tag("feat-1")
              end

              let(:include_wip_pacts_since) { (Date.today - 100).to_datetime }

              it "uses user date without capping" do
                expect(subject.size).to eq 1
              end
            end

            context "with user date within 14 days" do
              before do
                td.create_provider("bar")
                  .create_provider_version("333", tag_names: provider_tags)
                  .create_pact_with_hierarchy("foo", "1", "bar")
                  .create_consumer_version_tag("feat-1")
              end

              let(:include_wip_pacts_since) { (Date.today - 10).to_datetime }

              it "uses user date" do
                expect(subject.size).to eq 1
              end
            end

            context "with no date specified" do
              before do
                td.create_provider("bar")
                  .create_provider_version("333", tag_names: provider_tags)
                  .create_pact_with_hierarchy("foo", "1", "bar")
                  .create_consumer_version_tag("feat-1")
              end

              let(:options) { {} }

              it "requires date parameter" do
                expect { subject }.to raise_error(KeyError, /include_wip_pacts_since/)
              end
            end
          end
        end
      end
    end
  end
end
