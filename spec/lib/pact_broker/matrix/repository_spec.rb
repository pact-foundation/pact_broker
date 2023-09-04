require "pact_broker/matrix/repository"
require "pact_broker/matrix/unresolved_selector"

module PactBroker
  module Matrix
    describe Repository do
      def build_selectors(hash)
        hash.collect do | key, value |
          UnresolvedSelector.new(pacticipant_name: key, pacticipant_version_number: value)
        end
      end

      def shorten_row row
        "#{row.consumer_name}#{row.consumer_version_number} #{row.provider_name}#{row.provider_version_number || '?'} n#{row.verification_number || '?'}"
      end

      def shorten_rows rows
        rows.collect{ |r| shorten_row(r) }
      end

      describe "find" do
        before do
          # A1 - B1 n1
          # A1 - B1 n2
          # A1 - B2 n3
          # A1 - C1 n1
          # A2 - C3 n1
          # A2 - B?
          td.create_pact_with_hierarchy("A", "1", "B")
            .create_verification(provider_version: "1", success: false).comment("A1 - B1 n1")
            .create_verification(provider_version: "1", number: 2, success: true).comment("A1 - B1 n2")
            .create_verification(provider_version: "2", number: 3, success: true).comment("A1 - B2 n3")
            .create_provider("C")
            .create_pact
            .create_verification(provider_version: "1").comment("A1 - C1 n1")
            .create_consumer_version("2")
            .create_pact.comment("A2")
            .create_verification(provider_version: "3").comment("A2 - C3 n1")
            .use_provider("B")
            .create_pact.comment("A2 - B?")
        end

        subject { shorten_rows(rows) }
        let(:rows) { Repository.new.find(selectors, options) }

        let(:options) { { latestby: latestby } }
        let(:latestby) { nil }
        let(:a1_b1_n1) { "A1 B1 n1" }
        let(:a1_b1_n2) { "A1 B1 n2" }
        let(:a1_b2_n3) { "A1 B2 n3" }
        let(:a1_c1_n1) { "A1 C1 n1" }
        let(:a2_b__n_) { "A2 B? n?" }

        context "when just the consumer name is specified" do
          let(:selectors) { build_selectors("A" => nil) }

          context "when no latestby is specified" do
            it "returns all rows" do
              expect(subject).to include a1_b1_n1
              expect(subject).to include a1_b1_n2
              expect(subject).to include a1_c1_n1
              expect(subject).to include a2_b__n_
              expect(subject.size).to eq 6
            end
          end

          context "when latestby=cvpv" do
            let(:latestby) { "cvpv" }

            it "returns the latest rows per consumer version/provider version" do
              expect(subject).to_not include a1_b1_n1
              expect(subject).to include a1_b1_n2
              expect(subject).to include a1_c1_n1
              expect(subject).to include a2_b__n_
              expect(subject.size).to eq 5
            end
          end

          context "when latestby=cvp", can_i_deploy: true do
            let(:latestby) { "cvp" }

            it "returns the latest row for each provider for each consumer version" do
              expect(subject).to_not include a1_b1_n1
              expect(subject).to_not include a1_b1_n2
              expect(subject).to include a1_b2_n3
              expect(subject).to include a1_c1_n1
              expect(subject).to include a2_b__n_
              expect(subject.size).to eq 4
            end
          end

          context "when latestby=cp" do
            let(:latestby) { "cp" }

            it "returns the latest rows per consumer/provider" do
              expect(subject).to include "A2 C3 n1"
              expect(subject).to include "A2 B? n?"
              expect(subject.size).to eq 2
            end
          end
        end

        context "when the consumer name/version are specified" do
          let(:selectors) { build_selectors("A" => "1") }

          context "when no latestby is specified" do
            it "returns all the rows for the consumer version" do
              expect(subject.size).to eq 4
            end
          end

          context "when latestby=cvpv" do
            let(:latestby) { "cvpv" }

            it "returns the latest verification for each provider version for the specified consumer version" do
              expect(subject).to_not include a1_b1_n1
              expect(subject).to include a1_b1_n2
              expect(subject).to include a1_c1_n1
              expect(subject.size).to eq 3
            end
          end

          context "when latestby=cvp", can_i_deploy: true do
            let(:latestby) { "cvp" }

            it "returns the latest verifications for each provider for the specified consumer version" do
              expect(subject).to_not include a1_b1_n1
              expect(subject).to_not include a1_b1_n2
              expect(subject).to include a1_b2_n3
              expect(subject).to include a1_c1_n1
              expect(subject.size).to eq 2
            end
          end

          context "when latestby=cp" do
            let(:latestby) { "cp" }

            it "returns the same as latestby=cvp" do
              expect(subject).to_not include a1_b1_n1
              expect(subject).to_not include a1_b1_n2
              expect(subject).to include a1_b2_n3
              expect(subject).to include a1_c1_n1
              expect(subject.size).to eq 2
            end
          end
        end

        context "when the consumer name/version and the provider name are specified" do
          let(:selectors) { build_selectors("A" => "1", "B" => nil) }

          context "when no latestby is specified" do
            it "returns all the rows for the given consumer version and given provider" do
              expect(subject).to include a1_b1_n1
              expect(subject).to include a1_b1_n2
              expect(subject).to include a1_b2_n3
              expect(subject).to_not include a1_c1_n1
              expect(subject.size).to eq 3
            end
          end

          context "when latestby=cvpv" do
            let(:latestby) { "cvpv" }

            it "returns the latest verification for each provider version for the given consumer version" do
              expect(subject).to_not include a1_b1_n1
              expect(subject).to include a1_b1_n2
              expect(subject).to include a1_b2_n3
              expect(subject).to_not include a1_c1_n1
              expect(subject.size).to eq 2
            end
          end

          context "when latestby=cvp" do
            let(:latestby) { "cvp" }

            it "returns the latest verification for the given provider for the given consumer version" do
              expect(subject).to_not include a1_b1_n1
              expect(subject).to_not include a1_b1_n2
              expect(subject).to include a1_b2_n3
              expect(subject).to_not include a1_c1_n1
              expect(subject.size).to eq 1
            end
          end

          context "when latestby=cp" do
            let(:latestby) { "cp" }

            it "returns the same as latestby=cvp" do
              expect(subject).to_not include a1_b1_n1
              expect(subject).to_not include a1_b1_n2
              expect(subject).to include a1_b2_n3
              expect(subject).to_not include a1_c1_n1
              expect(subject.size).to eq 1
            end
          end
        end

        context "when the consumer name/version and provider name/version are specified" do
          let(:selectors) { build_selectors("A" => "1", "B" => "1") }

          context "when no latestby is specified" do
            it "returns all the rows for the given consumer/version and given provider/version" do
              expect(subject).to include a1_b1_n1
              expect(subject).to include a1_b1_n2
              expect(subject).to_not include a1_b2_n3
              expect(subject).to_not include a1_c1_n1
              expect(subject.size).to eq 2
            end
          end

          context "when latestby=cvpv" do
            let(:latestby) { "cvpv" }

            it "returns the latest verification for the given provider version for the given consumer version" do
              expect(subject).to include a1_b1_n2
              expect(subject.size).to eq 1
            end
          end

          context "when latestby=cvp" do
            let(:latestby) { "cvp" }

            it "returns the same as latestby=cvpv" do
              expect(subject).to include a1_b1_n2
              expect(subject.size).to eq 1
            end
          end

          context "when latestby=cp" do
            let(:latestby) { "cp" }

            it "returns the same as latestby=cvp" do
              expect(subject).to include a1_b1_n2
              expect(subject.size).to eq 1
            end
          end
        end
      end

      describe "find" do
        describe "when a pact for a particular consumer version is published, then re-published with different content, then published again with the original content" do
          before do
            first_pact = td.create_pact_with_hierarchy("billy", "1", "bobby").and_return(:pact)
            td.create_verification(provider_version: "1")
              .revise_pact
              .revise_pact(first_pact.json_content)
          end

          let(:selectors) { build_selectors("billy" => nil, "bobby" => nil) }

          subject { Repository.new.find(selectors, options) }

          context "when latestby: cvpv" do
            let(:options) { { latestby: "cvpv" } }

            it "only includes the row for the latest revision" do
              expect(subject.size).to eq 1
              expect(subject.find { | s | s.pact_revision_number == 3} ).to_not be nil
            end
          end

          context "when latestby: cvp" do
            let(:options) { { latestby: "cvp" } }

            it "only includes the row for the latest revision" do
              expect(subject.size).to eq 1
              expect(subject.find { | s | s.pact_revision_number == 3} ).to_not be nil
            end
          end

          context "when latestby: nil" do
            let(:options) { {} }

            it "includes all the rows" do
              expect(subject.size).to eq 3
            end
          end
        end
      end

      describe "find" do
        let(:options) { {} }

        subject { Repository.new.find(selectors, options) }

        context "when a pact is revised, then verified" do
          before do
            td.create_pact_with_hierarchy("A", "1", "B")
              .revise_pact
              .create_verification(provider_version: "1")
          end

          context "when latestby=cvpv" do
            let(:selectors) { build_selectors("A" => "1", "B" => "1")}
            let(:options) { { latestby: "cvpv" } }

            it "returns one row" do
              expect(shorten_rows(subject)).to eq ["A1 B1 n1"]
            end
          end
        end

        context "when the provider version resource exists but there is no verification for that version" do
          before do
            # A/1.2.3 -> B
            # B/2.0.0
            # C/3.0.0
            td.create_pact_with_hierarchy("A", "1.2.3", "B")
              .use_provider("B")
              .create_version("2.0.0")
              .create_provider("C")
              .create_version("3.0.0")
              .create_pact
          end
          let(:selectors) { build_selectors("A" => "1.2.3", "B" => "2.0.0", "C" => "3.0.0") }

          it "returns a row for each pact" do
            expect(subject.size).to eq 2
          end

          it "returns an row with a blank provider_version_number" do
            expect(subject).to include_hash_matching consumer_name: "A",
              provider_name: "B",
              consumer_version_number: "1.2.3",
              provider_version_number: nil

            expect(subject).to include_hash_matching({consumer_name: "A",
              provider_name: "C",
              consumer_version_number: "1.2.3",
              provider_version_number: nil})
          end

          context "when only 2 version selectors are specified" do
            let(:selectors) { build_selectors("A" => "1.2.3", "B" => "2.0.0") }

            it "only returns 1 row" do
              expect(subject.size).to eq 1
            end
          end
        end

        context "when only one pacticipant/version is specified and it is a consumer" do
          before do
            td.create_pact_with_hierarchy("A", "1.2.3", "B")
              .create_verification(provider_version: "4.5.6")
              .create_provider("D")
              .create_pact
              .create_verification(provider_version: "6.7.8")
              .create_consumer_version("5.5.5")
              .create_pact
              .create_verification(provider_version: "4.5.6")
          end

          let(:selectors) { build_selectors("A" => "1.2.3") }

          it "returns a row for each verification for that version" do
            expect(subject.size).to eq 2
            expect(subject.collect(&:consumer_version_number).sort).to eq ["1.2.3", "1.2.3"]
            expect(subject.collect(&:provider_version_number).sort).to eq ["4.5.6", "6.7.8"]
          end
        end

        context "when only one pacticipant name is specified and it is a consumer" do
          before do
            td.create_pact_with_hierarchy("A", "1.2.3", "B")
              .create_verification(provider_version: "4.5.6")
              .create_provider("D")
              .create_pact
              .create_pact_with_hierarchy("X", "1.2.3", "Y")
          end

          let(:selectors) { build_selectors("A" => nil) }

          it "returns a row for each verification for the pacticipant" do
            expect(subject.collect(&:consumer_name).uniq).to eq ["A"]
            provider_version_numbers = subject.collect(&:provider_version_number)
            expect(provider_version_numbers).to include nil
            expect(provider_version_numbers).to include "4.5.6"
          end
        end

        context "when only one pacticipant/version is specified and it is a provider" do
          before do
            td.create_pact_with_hierarchy("A", "1.2.3", "B")
              .create_verification(provider_version: "4.5.6")
              .create_consumer("D")
              .create_consumer_version("3.4.5")
              .create_pact
              .create_verification(provider_version: "4.5.6")
              .create_verification(provider_version: "6.7.8", number: 2)
          end

          let(:selectors) { build_selectors("B" => "4.5.6") }

          it "returns a row for each verification for that version" do
            expect(subject.size).to eq 2
            expect(subject.collect(&:consumer_version_number).sort).to eq ["1.2.3", "3.4.5"]
            expect(subject.collect(&:provider_version_number).sort).to eq ["4.5.6", "4.5.6"]
          end
        end

        context "when only one pacticipant name is specified and it is a provider" do
          before do
            td.create_pact_with_hierarchy("A", "1.2.3", "B")
              .create_verification(provider_version: "4.5.6")
              .create_consumer("D")
              .create_consumer_version("3.4.5")
              .create_pact
              .create_verification(provider_version: "4.5.6")
              .create_verification(provider_version: "6.7.8", number: 2)
          end

          before do
            options.delete(:scope)
          end

          let(:selectors) { build_selectors("B" => nil) }

          it "returns a row for each verification for that version" do
            expect(subject.size).to eq 3
            expect(subject.collect(&:consumer_version_number).sort).to eq ["1.2.3", "3.4.5", "3.4.5"]
            expect(subject.collect(&:provider_version_number).sort).to eq ["4.5.6", "4.5.6", "6.7.8"]
          end
        end

        context "when only one pacticipant/version is specified and it is a consumer and provider" do
          before do
            td.create_pact_with_hierarchy("A", "1", "B")
              .create_verification(provider_version: "1")
              .create_verification(provider_version: "2", number: 2, success: false)
              .create_verification(provider_version: "4", number: 3)
              .create_provider_version("5")
              .use_consumer("B")
              .use_consumer_version("1")
              .create_provider("C")
              .create_pact
              .create_verification(provider_version: "1", success: false)
          end

          let(:selectors) { build_selectors("B" => "1") }

          it "returns rows where the pacticipant is the consumer and rows where the pacticipant is the provider" do
            # A/1 and B/1
            # B/1 and C/1
            expect(subject.size).to eq 2
          end
        end

        context "when compability is required with all versions with a given tag" do
          before do
            td.create_pact_with_hierarchy("android app", "1", "BFF")
              .create_consumer_version_tag("prod")
              .create_verification(provider_version: "5", comment: "included")
              .create_consumer_version("2", tag_name: "prod")
              .create_pact
              .create_verification(provider_version: "5", comment: "included")
              .create_consumer_version("3")
              .create_pact
              .create_verification(provider_version: "5", comment: "not included")
              .create_consumer("ios app")
              .create_consumer_version("20", tag_name: "prod")
              .create_pact
              .create_verification(provider_version: "5", comment: "not included")
          end

          context "when the other service is specifically named" do
            let(:selectors) do
              [
                UnresolvedSelector.new(pacticipant_name: "android app", tag: "prod"),
                UnresolvedSelector.new(pacticipant_name: "BFF", pacticipant_version_number: "5")
              ]
            end

            let(:options) { {} }

            it "returns the matrix for all of the versions for the specified pacticipants with the given tag" do
              expect(subject).to include_hash_matching(consumer_version_number: "1")
              expect(subject).to include_hash_matching(consumer_version_number: "2")
              expect(subject).to_not include_hash_matching(consumer_version_number: "3")
              expect(subject).to_not include_hash_matching(consumer_name: "ios app")
            end
          end

          context "when the other service is not specifically named" do
            let(:selectors) do
              [
                UnresolvedSelector.new(pacticipant_name: "BFF", pacticipant_version_number: "5")
              ]
            end

            let(:options) { { tag: "prod" } }

            it "returns the matrix for all of the versions with the given tag" do
              expect(subject).to include_hash_matching(consumer_name: "android app", consumer_version_number: "1")
              expect(subject).to include_hash_matching(consumer_name: "android app", consumer_version_number: "2")
              expect(subject).to include_hash_matching(consumer_name: "ios app", consumer_version_number: "20")
            end
          end
        end

        context "using the success option" do
          before do
            td.create_pact_with_hierarchy("A", "1.2.3", "B")
              .create_verification(provider_version: "1.0.0")
              .create_consumer_version("1.2.4")
              .create_pact
              .create_verification(provider_version: "2.0.0", success: false)
              .create_consumer_version("1.2.5")
              .create_pact
          end

          let(:selectors) { build_selectors("A" => nil, "B" => nil) }

          context "when the success option is not set" do
            before do
              options.delete(:success)
            end

            it "returns all rows specified by the selectors" do
              expect(subject.size).to eq 3
            end
          end

          context "when the success option is true" do
            before do
              options[:success] = [true]
            end

            it "only includes successes" do
              expect(subject).to include_hash_matching provider_version_number: "1.0.0"
              expect(subject.size).to eq 1
            end
          end

          context "when the success option is false" do
            before do
              options[:success] = [false]
            end

            it "only includes failures" do
              expect(subject).to include_hash_matching provider_version_number: "2.0.0"
              expect(subject.size).to eq 1
            end
          end

          context "when the success option is nil" do
            before do
              options[:success] = [nil]
            end

            it "only includes unverified rows" do
              expect(subject).to include_hash_matching provider_version_number: nil
              expect(subject.size).to eq 1
            end
          end

          context "when multiple success options are specified" do
            before do
              options[:success] = [false, nil]
            end

            it "returns all matching rows" do
              # postgres orders differently, and ruby array sort blows up with a nil string
              provider_version_numbers = subject.collect(&:provider_version_number)
              expect(provider_version_numbers).to include nil
              expect(provider_version_numbers).to include "2.0.0"
              expect(provider_version_numbers.size).to eq 2
            end
          end
        end

        context "when the latest tag is specified for a provider" do
          before do
            td.create_pact_with_hierarchy("A", "1.2.3", "B")
              .create_verification(provider_version: "1.0.0")
              .use_provider_version("1.0.0")
              .create_provider_version_tag("prod")
              .create_verification(provider_version: "2.0.0", number: 2)
              .use_provider_version("2.0.0")
              .create_provider_version_tag("prod")
              .create_verification(provider_version: "3.0.0", number: 3)
          end

          let(:selectors) do
            [
              UnresolvedSelector.new(pacticipant_name: "A", pacticipant_version_number: "1.2.3"),
              UnresolvedSelector.new(pacticipant_name: "B", latest: true, tag: "prod")
            ]
          end

          it "returns the row for the version " do
            expect(subject).to include_hash_matching provider_version_number: "2.0.0"
            expect(subject.size).to eq 1
          end

          it "returns the tag information" do
            expect(subject.first.provider_version_tags).to include(have_attributes(name: "prod", latest?: true))
          end
        end

        context "when the latest version is specified for a provider without a tag" do
          before do
            td.create_pact_with_hierarchy("A", "1.2.3", "B")
              .create_verification(provider_version: "1.0.0")
              .use_provider_version("1.0.0")
              .create_verification(provider_version: "2.0.0", number: 2)
              .use_provider_version("2.0.0")
              .create_verification(provider_version: "3.0.0", number: 3)
          end

          let(:selectors) do
            [
              UnresolvedSelector.new(pacticipant_name: "A", pacticipant_version_number: "1.2.3"),
              UnresolvedSelector.new(pacticipant_name: "B", latest: true)
            ]
          end

          it "returns the row for the version " do
            expect(subject).to include_hash_matching provider_version_number: "3.0.0"
            expect(subject.size).to eq 1
          end
        end

        context "when the latest version is specified for a provider ignoring tags but the latest known version for a provider does not have a verification" do
          before do
            td.create_pact_with_hierarchy("A", "1.2.3", "B")
              .create_verification(provider_version: "1.0.0")
              .create_provider_version("5.0.0")
          end

          let(:selectors) do
            [
              UnresolvedSelector.new(pacticipant_name: "A", pacticipant_version_number: "1.2.3"),
              UnresolvedSelector.new(pacticipant_name: "B", latest: true)
            ]
          end

          it "returns a row with no verification" do
            expect(subject.size).to eq 1
            expect(subject.first).to_not have_verification
          end
        end
      end

      describe "find with global latest and tag specified" do
        subject { shorten_rows(Repository.new.find(selectors, options)) }

        context "with one consumer/version and latest tag specified for all the other pacticipants" do
          before do
            td.create_pact_with_hierarchy("A", "1", "B")
              .create_verification(provider_version: "1")
              .create_verification(provider_version: "2", number: 2)
              .use_provider_version("1")
              .create_provider_version_tag("prod")
              .create_provider("C")
              .create_pact
              .create_verification(provider_version: "3")
              .use_provider_version("3")
              .create_provider_version_tag("prod")
              .create_verification(provider_version: "4", number: 2)
          end

          let(:selectors) { build_selectors("A"=> "1") }
          let(:options) { { tag: "prod", latest: true } }

          it "finds the matrix for the latest tagged versions of each of the other other pacticipants" do
            expect(subject).to include "A1 B1 n1"
            expect(subject).to include "A1 C3 n1"
            expect(subject.size).to eq 2
          end
        end

        context "with one consumer/version and latest specified for all the other pacticipants" do
          before do
            td.create_pact_with_hierarchy("A", "1", "B")
              .create_verification(provider_version: "1")
              .create_verification(provider_version: "2", number: 2)
              .use_provider_version("1")
              .create_provider("C")
              .create_pact
              .create_verification(provider_version: "3")
              .create_verification(provider_version: "4", number: 2)
          end

          let(:selectors) { build_selectors("A"=> "1") }
          let(:options) { { latest: true } }

          it "finds the matrix for the latest tagged versions of each of the other other pacticipants" do
            expect(subject).to include "A1 B2 n2"
            expect(subject).to include "A1 C4 n2"
            expect(subject.size).to eq 2
          end
        end

        context "with one pacticipant without a version and latest tag specified for all the other pacticipants" do
          before do
            td.create_pact_with_hierarchy("A", "1", "B")
              .create_verification(provider_version: "1")
              .create_verification(provider_version: "2", number: 2)
              .use_provider_version("1")
              .create_provider_version_tag("prod")
              .create_provider("C")
              .create_pact
              .create_verification(provider_version: "3")
              .use_provider_version("3")
              .create_provider_version_tag("prod")
              .create_verification(provider_version: "4", number: 2)
              .create_consumer_version("2")
              .create_pact
          end

          let(:selectors) { build_selectors("A"=> nil) }
          let(:options) { { tag: "prod", latest: true } }

          it "finds the matrix for the latest tagged versions of each of the other other pacticipants" do
            expect(subject).to include "A1 B1 n1"
            expect(subject).to include "A1 C3 n1"
            expect(subject).to include "A2 C? n?"
            expect(subject.size).to eq 3
          end
        end

        context "with one pacticipant/version that is both a consumer and provider and latest tag specified for all the other pacticipants" do
          before do
            td.create_pact_with_hierarchy("A", "1", "B")
              .create_consumer_version_tag("prod")
              .create_verification(provider_version: "1")
              .use_provider_version("1")
              .use_consumer("B")
              .use_consumer_version("1")
              .create_provider("C")
              .create_pact
              .create_verification(provider_version: "3")
              .use_provider_version("3")
              .create_provider_version_tag("prod")
              .create_verification(provider_version: "4", number: 2)
          end

          let(:selectors) { build_selectors("B"=> "1") }
          let(:options) { { tag: "prod", latest: true } }

          it "finds the matrix for the latest tagged versions of each of the other other pacticipants" do
            expect(subject).to include "A1 B1 n1"
            expect(subject).to include "B1 C3 n1"
            expect(subject.size).to eq 2
          end
        end

        context "with one pacticipant/latest tag and latest tag specified for all the other pacticipants" do
          before do
            td.create_pact_with_hierarchy("A", "1", "B")
              .create_consumer_version_tag("dev")
              .create_verification(provider_version: "1")
              .use_provider_version("1")
              .create_provider_version_tag("prod")
              .create_provider("C")
              .create_pact
              .create_verification(provider_version: "3")
              .use_provider_version("3")
              .create_provider_version_tag("prod")
              .create_verification(provider_version: "4", number: 2)
          end

          let(:selectors) { [UnresolvedSelector.new(pacticipant_name: "A", latest: true, tag: "dev")] }
          let(:options) { { tag: "prod", latest: true } }

          it "finds the matrix for the latest tagged versions of each of the other other pacticipants" do
            expect(subject).to include "A1 B1 n1"
            expect(subject).to include "A1 C3 n1"
            expect(subject).to_not include "A1 C4 n2"
            expect(subject.size).to eq 2
          end
        end

      end

      describe "#find_for_consumer_and_provider" do
        before do
          TestDataBuilder.new
            .create_pact_with_hierarchy("Consumer", "1.2.3", "Provider")
            .create_verification(provider_version: "6.7.8", execution_date: DateTime.new(2016))
            .revise_pact
            .create_verification(provider_version: "4.5.6", execution_date: DateTime.new(2017))
            .create_consumer_version("2.0.0")
            .create_pact
        end

        subject { Repository.new.find_for_consumer_and_provider("Consumer", "Provider") }

        it "returns the latest revision of each pact" do
          expect(subject.count).to eq 2
          expect(subject[0].consumer_version_number).to eq "2.0.0"
          expect(subject[1].consumer_version_number).to eq "1.2.3"
        end

        it "returns the latest verification for the pact version" do
          expect(subject[1].provider_version_number).to eq "4.5.6"
        end

        it "doesn't matter which way you order the pacticipant names" do
          expect(subject).to eq(Repository.new.find_for_consumer_and_provider "Provider", "Consumer")
        end
      end

      describe "find pact_broker-client issue 33" do
        # foo1.0.0 bar10.0.0 n1
        # foo1.0.0 baz9.0.0 n1
        before do
          td
          .create_consumer("foo")
          .create_provider("bar")
          .create_consumer_version("1.0.0")
          .create_pact
          .create_verification(provider_version: "10.0.0", tag_names: ["prod"])
          .create_provider("baz")
          .create_pact
          .create_verification(provider_version: "9.0.0")
          .create_consumer_version("2.0.0")
          .create_pact
          .create_verification(provider_version: "20.0.0", tag_names: ["prod"])
        end

        let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "foo", pacticipant_version_number: "1.0.0")] }
        let(:options) { { latestby: "cvp", latest: true, tag: "prod" } }
        let(:results) { Repository.new.find(selectors, options) }

        subject { shorten_rows(results) }

        it "only returns a row for the foo pact version that has been verified by the current production version of bar" do
          expect(subject).to eq ["foo1.0.0 bar10.0.0 n1", "foo1.0.0 baz? n?"]
        end

        it "returns 2 integrations" do
          expect(results.integrations.size).to eq 2
        end
      end

      describe "when the consumer is not specified and multiple consumer versions have been verified by this provider version and no target is specified" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_verification(provider_version: "5")
            .create_consumer_version("2")
            .create_pact
            .create_verification(provider_version: "5")
        end

        subject { Repository.new.find(selectors, options) }

        let(:options) { { latestby: "cvp" } }

        let(:selectors) do
          [ UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "5") ]
        end

        it "returns a row for each consumer version" do
          expect(subject.rows.size).to eq 2
          expect(subject.rows.last.consumer_version_number).to eq "1"
          expect(subject.rows.first.consumer_version_number).to eq "2"
        end
      end

      describe "deploying a provider when there is a three way dependency between 3 pacticipants" do
        before do
          # A->B, A->C, B->C, deploying C
          td.create_pact_with_hierarchy("B", "1", "C")
            .create_verification(provider_version: "10")
            .create_consumer("A")
            .create_consumer_version("2")
            .create_pact
            .create_verification(provider_version: "10")
            .use_provider("B")
            .create_pact
        end

        let(:selectors) { [ UnresolvedSelector.new(pacticipant_name: "C", pacticipant_version_number: "10") ] }
        let(:options) { { latestby: "cvp", limit: "100", latest: true} }
        let(:rows) { Repository.new.find(selectors, options) }

        subject { shorten_rows(rows) }

        it "only includes rows that involve the specified pacticipant" do
          expect(subject.all?{ | row | row.include?("C") } ).to be true
        end
      end
    end
  end
end
