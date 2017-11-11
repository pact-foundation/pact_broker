require 'pact_broker/matrix/repository'

module PactBroker
  module Matrix
    describe Repository do
      let(:td) { TestDataBuilder.new}

      def build_selectors(hash)
        hash.collect do | key, value |
          { pacticipant_name: key, pacticipant_version_number: value }
        end
      end

      def shorten_row row
        "#{row[:consumer_name]}#{row[:consumer_version_number]} #{row[:provider_name]}#{row[:provider_version_number] || '?'} n#{row[:verification_number] || '?'}"
      end

      def shorten_rows rows
        rows.collect{ |r| shorten_row(r) }
      end

      describe "find" do
        before do
          # A1 - B1
          # A1 - B1 r2
          # A1 - B2 r3
          # A1 - C1
          # A2 - B?
          # A2 - C2
          td.create_pact_with_hierarchy("A", "1", "B")
            .create_verification(provider_version: '1', success: false)
            .create_verification(provider_version: '1', number: 2, success: true)
            .create_verification(provider_version: '2', number: 3, success: true)
            .create_provider("C")
            .create_pact
            .create_verification(provider_version: '1')
            .create_consumer_version("2")
            .create_pact
            .create_verification(provider_version: '3')
            .use_provider("B")
            .create_pact
        end

        subject { shorten_rows(Repository.new.find(selectors, options)) }

        let(:options) { { latestby: latestby } }
        let(:latestby) { nil }
        let(:a1_b1_n1) { "A1 B1 n1" }
        let(:a1_b1_n2) { "A1 B1 n2" }
        let(:a1_b2_n3) { "A1 B2 n3" }
        let(:a1_c1_n1) { "A1 C1 n1" }
        let(:a2_b__n_) { "A2 B? n?" }

        context "when a limit is specified" do
          let(:selectors) { build_selectors('A' => nil) }
          let(:options) { {limit: 1} }

          it "returns fewer rows than the limit (because some of the logic is done in the code, there may be fewer than the limit - need to fix this)" do
            expect(subject).to eq ["A2 B? n?"]
          end
        end

        context "when just the consumer name is specified" do
          let(:selectors) { build_selectors('A' => nil) }

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
            let(:latestby) { 'cvpv' }

            it "returns the latest rows per consumer version/provider version" do
              expect(subject).to_not include a1_b1_n1
              expect(subject).to include a1_b1_n2
              expect(subject).to include a1_c1_n1
              expect(subject).to include a2_b__n_
              expect(subject.size).to eq 5
            end
          end

          context "when latestby=cvp" do
            let(:latestby) { 'cvp' }

            it "returns the latest row for each provider for each consumer version" do
              expect(subject).to_not include a1_b1_n1
              expect(subject).to_not include a1_b1_n2
              expect(subject).to include a1_b2_n3
              expect(subject).to include a1_c1_n1
              expect(subject).to include a2_b__n_
              expect(subject.size).to eq 4
            end
          end

          context "when latestby=cp", pending: true do
            let(:latestby) { 'cp' }

            it "returns the latest rows per consumer/provider" do
              expect(subject).to include "A2 C3 n1"
              expect(subject).to include "A2 B? n?"
              expect(subject).to include a1_c1_n1
              expect(subject).to_not include a1_b2_n3
              expect(subject.size).to eq 2
            end
          end
        end

        context "when the consumer name/version are specified" do
          let(:selectors) { build_selectors('A' => '1') }

          context "when no latestby is specified" do
            it "returns all the rows for the consumer version" do
              expect(subject.size).to eq 4
            end
          end

          context "when latestby=cvpv" do
            let(:latestby) { 'cvpv' }

            it "returns the latest verification for each provider version for the specified consumer version" do
              expect(subject).to_not include a1_b1_n1
              expect(subject).to include a1_b1_n2
              expect(subject).to include a1_c1_n1
              expect(subject.size).to eq 3
            end
          end

          context "when latestby=cvp" do
            let(:latestby) { 'cvp' }

            it "returns the latest verifications for each provider for the specified consumer version" do
              expect(subject).to_not include a1_b1_n1
              expect(subject).to_not include a1_b1_n2
              expect(subject).to include a1_b2_n3
              expect(subject).to include a1_c1_n1
              expect(subject.size).to eq 2
            end
          end

          context "when latestby=cp" do
            let(:latestby) { 'cp' }

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
          let(:selectors) { build_selectors('A' => '1', 'B' => nil) }

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
            let(:latestby) { 'cvpv' }

            it "returns the latest verification for each provider version for the given consumer version" do
              expect(subject).to_not include a1_b1_n1
              expect(subject).to include a1_b1_n2
              expect(subject).to include a1_b2_n3
              expect(subject).to_not include a1_c1_n1
              expect(subject.size).to eq 2
            end
          end

          context "when latestby=cvp" do
            let(:latestby) { 'cvp' }

            it "returns the latest verification for the given provider for the given consumer version" do
              expect(subject).to_not include a1_b1_n1
              expect(subject).to_not include a1_b1_n2
              expect(subject).to include a1_b2_n3
              expect(subject).to_not include a1_c1_n1
              expect(subject.size).to eq 1
            end
          end

          context "when latestby=cp" do
            let(:latestby) { 'cp' }

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
          let(:selectors) { build_selectors('A' => '1', 'B' => '1') }

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
            let(:latestby) { 'cvpv' }

            it "returns the latest verification for the given provider version for the given consumer version" do
              expect(subject).to include a1_b1_n2
              expect(subject.size).to eq 1
            end
          end

          context "when latestby=cvp" do
            let(:latestby) { 'cvp' }

            it "returns the same as latestby=cvpv" do
              expect(subject).to include a1_b1_n2
              expect(subject.size).to eq 1
            end
          end

          context "when latestby=cp" do
            let(:latestby) { 'cp' }

            it "returns the same as latestby=cvp" do
              expect(subject).to include a1_b1_n2
              expect(subject.size).to eq 1
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
            let(:selectors) { build_selectors('A' => '1', 'B' => '1')}
            let(:options) { { latestby: 'cvpv' } }

            it "returns one row" do
              expect(shorten_rows(subject)).to eq ['A1 B1 n1']
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
            expect(subject.collect{|r| r[:consumer_version_number]}.sort).to eq ["1.2.3", "1.2.3"]
            expect(subject.collect{|r| r[:provider_version_number]}.sort).to eq ["4.5.6", "6.7.8"]
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
            expect(subject.collect{|r| r[:consumer_name]}.uniq).to eq ["A"]
            provider_version_numbers = subject.collect{|r| r[:provider_version_number]}
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
            expect(subject.collect{|r| r[:consumer_version_number]}.sort).to eq ["1.2.3", "3.4.5"]
            expect(subject.collect{|r| r[:provider_version_number]}.sort).to eq ["4.5.6", "4.5.6"]
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
            expect(subject.collect{|r| r[:consumer_version_number]}.sort).to eq ["1.2.3", "3.4.5", "3.4.5"]
            expect(subject.collect{|r| r[:provider_version_number]}.sort).to eq ["4.5.6", "4.5.6", "6.7.8"]
          end
        end

        context "when only one pacticipant/version is specified and it is a consumer and provider" do
          before do
            td.create_pact_with_hierarchy("A", "1", "B")
              .create_verification(provider_version: '1')
              .create_verification(provider_version: '2', number: 2, success: false)
              .create_verification(provider_version: '4', number: 3)
              .create_provider_version("5")
              .use_consumer("B")
              .use_consumer_version("1")
              .create_provider("C")
              .create_pact
              .create_verification(provider_version: '1', success: false)
          end

          let(:selectors) { build_selectors("B" => "1") }

          it "returns rows where the pacticipant is the consumer and rows where the pacticipant is the provider" do
            # A/1 and B/1
            # B/1 and C/1
            expect(subject.size).to eq 2
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
              provider_version_numbers = subject.collect{ |r| r[:provider_version_number]}
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
              { pacticipant_name: "A", pacticipant_version_number: "1.2.3" },
              { pacticipant_name: "B", latest: true, tag: "prod" }
            ]
          end

          it "returns the row for the version " do
            expect(subject).to include_hash_matching provider_version_number: "2.0.0"
            expect(subject.size).to eq 1
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
              { pacticipant_name: "A", pacticipant_version_number: "1.2.3" },
              { pacticipant_name: "B", latest: true }
            ]
          end

          it "returns the row for the version " do
            expect(subject).to include_hash_matching provider_version_number: "3.0.0"
            expect(subject.size).to eq 1
          end
        end

        context "when the latest version is specified for a provider without a tag but the latest known version for a provider does not have a verification" do
          before do
            td.create_pact_with_hierarchy("A", "1.2.3", "B")
              .create_verification(provider_version: "1.0.0")
              .create_provider_version("5.0.0")
          end

          let(:selectors) do
            [
              { pacticipant_name: "A", pacticipant_version_number: "1.2.3" },
              { pacticipant_name: "B", latest: true }
            ]
          end

          it "returns no data - this may be confusing. Might need to re-think this logic." do
            expect(subject.size).to eq 0
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

          let(:selectors) { build_selectors('A'=> '1') }
          let(:options) { { tag: 'prod', latest: true } }

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

          let(:selectors) { build_selectors('A'=> '1') }
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

          let(:selectors) { build_selectors('A'=> nil) }
          let(:options) { { tag: 'prod', latest: true } }

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

          let(:selectors) { build_selectors('B'=> '1') }
          let(:options) { { tag: 'prod', latest: true } }

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

          let(:selectors) { [{ pacticipant_name: 'A', latest: true, tag: 'dev' } ] }
          let(:options) { { tag: 'prod', latest: true } }

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
          expect(subject[0][:consumer_version_number]).to eq "2.0.0"
          expect(subject[1][:consumer_version_number]).to eq "1.2.3"
        end

        it "returns the latest verification for the pact version" do
          expect(subject[1][:provider_version_number]).to eq "4.5.6"
        end

        it "doesn't matter which way you order the pacticipant names" do
          expect(subject).to eq(Repository.new.find_for_consumer_and_provider "Provider", "Consumer")
        end
      end

      describe "#find_compatible_pacticipant_versions" do
        let(:td) { TestDataBuilder.new }

        subject { Repository.new.find(selectors, success: [true], latestby: 'cvpv')}

        context "when compatible versions can be found" do
          before do
            td.create_pact_with_hierarchy("A", "1", "B")
              .create_verification(provider_version: '0')
              .revise_pact
              .create_verification(provider_version: '1')
              .create_verification(provider_version: '2', number: 2)
              .use_consumer("B")
              .use_consumer_version("1")
              .create_provider("C")
              .create_pact
              .create_verification(provider_version: '1')
              .use_consumer_version("2")
              .create_pact
              .create_verification(provider_version: '2')
              .create_verification(provider_version: '3', number: 2)
          end

          let(:selectors){ build_selectors("A" => "1", "B" => "2", "C" => "2") }

          it "returns matrix lines for each compatible version pair (A/1-B/2, B/2-C/2)" do
            expect(subject).to include_hash_matching(
              consumer_name: "A",
              consumer_version_number: "1",
              provider_name: "B",
              provider_version_number: "2",
              verification_number: 2
            )

            expect(subject).to include_hash_matching(
              consumer_name: "B",
              consumer_version_number: "2",
              provider_name: "C",
              provider_version_number: "2",
              verification_number: 1,
            )

            expect(subject.size).to eq 2
          end

          context "when one or more pacticipants does not have a version specified" do
            let(:selectors){ build_selectors("A" => "1", "B" => "2", "C" => nil) }
            let(:options) { { latestby: 'cvpv'} }

            it "returns all the rows for that pacticipant" do
              expect(subject).to include_hash_matching(provider_name: "C", provider_version_number: "2")
              expect(subject).to include_hash_matching(provider_name: "C", provider_version_number: "3")
              expect(subject.size).to eq 3
            end
          end

          context "none of the pacticipants have a version specified" do
            let(:selectors){ build_selectors("A" => nil, "B" => nil, "C" => nil) }

            it "returns all the rows" do
              expect(subject.size).to eq 5
            end
          end
        end

        context "when there is more than one compatible version pair" do
          before do
            td.create_pact_with_hierarchy("X", "1", "Y")
              .create_verification(provider_version: "1")
              .create_verification(provider_version: "1", number: 2)
          end

          let(:selectors){ build_selectors("X" => "1", "Y" => "1") }

          subject { Repository.new.find_compatible_pacticipant_versions(selectors) }

          it "returns the last line" do
            expect(subject.size).to eq 1
            expect(subject).to include_hash_matching verification_number: 2
          end
        end

        context "when there is more than one verification and the last one is a failure" do
          before do
            td.create_pact_with_hierarchy("X", "1", "Y")
              .create_verification(provider_version: "1")
              .create_verification(provider_version: "1", number: 2, success: false)
          end

          let(:selectors){ build_selectors("X" => "1", "Y" => "1") }

          subject { Repository.new.find_compatible_pacticipant_versions(selectors) }

          it "does not return a matrix line" do
            expect(subject.size).to eq 0
          end
        end

        context "when a pact is verified, but then revised and the new revision is not verified" do
          before do
            td.create_pact_with_hierarchy("X", "1", "Y")
              .create_verification(provider_version: "1")
              .revise_pact
          end

          let(:selectors){ build_selectors("X" => "1", "Y" => "1") }

          subject { Repository.new.find_compatible_pacticipant_versions(selectors) }

          it "does not return a matrix line" do
            expect(subject.size).to eq 0
          end
        end

        context "when the verification result is false" do
          before do
            TestDataBuilder.new
              .create_pact_with_hierarchy("D", "1", "E")
              .create_verification(provider_version: '1', success: false)
          end

          let(:selectors){ build_selectors("D" => "1", "E" => "1") }

          subject { Repository.new.find_compatible_pacticipant_versions(selectors) }

          it "does not return the matrix line" do
            expect(subject.count).to eq 0
          end
        end
      end
    end
  end
end
