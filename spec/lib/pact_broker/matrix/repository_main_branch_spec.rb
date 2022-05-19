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
        "#{row.consumer_name}#{row.consumer_version_number} #{row.provider_name}#{row.provider_version_number || '?'}"
      end

      def shorten_rows rows
        rows.collect{ |r| shorten_row(r) }
      end

      describe "find" do
        describe "deploying a consumer with the main branches of the provider" do
          before do
            td.create_pacticipant("Bar", main_branch: "develop")
              .publish_pact(consumer_name: "Foo", consumer_version_number: "1", provider_name: "Bar")
              .create_verification(provider_version: "1", branch: "develop")
              .create_verification(provider_version: "2", number: 2, branch: "develop")
              .create_verification(provider_version: "3", number: 3, branch: "not-develop")
              .create_pacticipant("Baz", main_branch: "main")
              .publish_pact(consumer_name: "Foo", consumer_version_number: "1", provider_name: "Baz")
              .create_verification(provider_version: "10", branch: "main")
              .create_verification(provider_version: "11", number: 2, branch: "main")
              .create_verification(provider_version: "12", number: 3, branch: "not-main")
          end

          subject { shorten_rows(rows) }

          let(:rows) { Repository.new.find(selectors, options) }

          let(:selectors) { build_selectors({ "Foo" => "1" })}
          let(:options) { { main_branch: true, latest: true } }

          it "returns the rows between the consumer and the provider's main branches" do
            expect(subject.sort).to eq ["Foo1 Bar2", "Foo1 Baz11"]
          end

          context "deploying a consumer with all versions of the provider's main branches (this doesn't even make sense)" do
            let(:options) { { main_branch: true } }

            it "returns the rows between the consumer and the latest version of each provider's main branch" do
              expect(subject.sort).to eq ["Foo1 Bar1", "Foo1 Bar2", "Foo1 Baz10", "Foo1 Baz11"]
            end
          end
        end

        describe "deploying a provider with the main branches of the consumers" do
          before do
            td.create_pacticipant("Foo", main_branch: "develop")
              .publish_pact(consumer_name: "Foo", consumer_version_number: "1", provider_name: "Bar", branch: "develop")
              .create_verification(provider_version: "1")
              .publish_pact(consumer_name: "Foo", consumer_version_number: "2", provider_name: "Bar", branch: "develop")
              .create_verification(provider_version: "1")
              .publish_pact(consumer_name: "Foo", consumer_version_number: "3", provider_name: "Bar", branch: "not-develop")
              .create_verification(provider_version: "1")
              .create_pacticipant("Beep", main_branch: "main")
              .publish_pact(consumer_name: "Beep", consumer_version_number: "1", provider_name: "Bar", branch: "main")
              .create_verification(provider_version: "1")
              .publish_pact(consumer_name: "Beep", consumer_version_number: "2", provider_name: "Bar", branch: "main")
              .create_verification(provider_version: "1")
              .publish_pact(consumer_name: "Beep", consumer_version_number: "3", provider_name: "Bar", branch: "not-main")
              .create_verification(provider_version: "1")
          end

          subject { shorten_rows(rows) }

          let(:rows) { Repository.new.find(selectors, options) }

          let(:selectors) { build_selectors({ "Bar" => "1" })}
          let(:options) { { main_branch: true, latest: true } }

          it "returns the rows between the provider and the latest version of each consumer's main branche" do
            expect(subject.sort).to eq ["Beep2 Bar1", "Foo2 Bar1"]
          end

          context "deploying a provider with all versions of the consumer's main branches (this doesn't even make sense)" do
            let(:options) { { main_branch: true } }

            it "returns the rows between the provider and the consumer's main branches" do
              expect(subject.sort).to eq ["Beep1 Bar1", "Beep2 Bar1", "Foo1 Bar1", "Foo2 Bar1"]
            end
          end
        end
      end
    end
  end
end
