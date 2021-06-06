require "pact_broker/matrix/parse_query"

module PactBroker
  module Matrix
    describe ParseQuery do
      describe ".call" do
        let(:query) { "q[][pacticipant]=Foo&q[][version]=1.2.3&q[][pacticipant]=Bar&q[][version]=9.9.9" }

        subject { ParseQuery.call(query) }

        it "extracts the pacticipant names and respective versions" do
          expect(subject.first).to eq([
            PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1.2.3"),
            PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "Bar", pacticipant_version_number: "9.9.9")
          ])
        end

        context "with spaces" do
          let(:query) { "q[][pacticipant]=Name%20With%20Spaces&q[][version]=1%202" }

          it "works" do
            expect(subject.first).to eq [{pacticipant_name: "Name With Spaces", pacticipant_version_number: "1 2"}]
          end
        end

        context "with no q" do
          let(:query) { "foo" }

          it "returns an empty hash" do
            expect(subject.first).to eq([])
          end
        end

        context "with an incorrect param names" do
          let(:query) { "q[][wrong]=Foo&q[][blah]=1.2.3" }

          it "returns nil keys or values" do
            expect(subject.first).to eq [{}]
          end
        end

        context "with no options specified" do
          let(:query) { "" }

          it "sets the defaults" do
            expect(subject.last).to eq(limit: "100", ignore_selectors: [])
          end
        end

        context "with just one status specified" do
          let(:query) { "success=true" }
          it "extracts the one status" do
            expect(subject.last).to include success: [true]
          end
        end

        context "with an array of statuses" do
          let(:query) { "success[]=true&success[]=false&success[]=" }
          it "extracts the statuses" do
            expect(subject.last).to include success: [true, false, nil]
          end
        end

        context "with success[]=" do
          let(:query) { "success[]=&foo=bar" }

          it "sets an array with a nil success" do
            expect(subject.last).to include success: [nil]
          end
        end

        context "with success=" do
          let(:query) { "success=&foo=bar" }

          it "sets an array with a nil success" do
            expect(subject.last).to include success: [nil]
          end
        end

        context "when latest is true" do
          let(:query) { "q[][pacticipant]=Foo&q[][latest]=true" }

          it "returns a selector with latest true" do
            expect(subject.first).to eq [{ pacticipant_name: "Foo", latest: true }]
          end
        end

        context "when global latest is true" do
          let(:query) { "q[][pacticipant]=Foo&latest=true" }

          it "returns options with latest true" do
            expect(subject.last).to include latest: true
          end
        end

        context "when latest is not true" do
          let(:query) { "q[][pacticipant]=Foo&q[][latest]=false" }

          it "returns a selector with no latest key" do
            expect(subject.first).to eq [{ pacticipant_name: "Foo" }]
          end
        end

        context "when there is a tag" do
          let(:query) { "q[][pacticipant]=Foo&q[][tag]=prod" }

          it "returns a selector with a tag" do
            expect(subject.first).to eq [{ pacticipant_name: "Foo", tag: "prod" }]
          end
        end

        context "when a limit is specified" do
          let(:query) { "limit=200" }

          it "sets the limit" do
            expect(subject.last[:limit]).to eq "200"
          end
        end

        context "when there are ignored selectors" do
          let(:query) { "q[][pacticipant]=Foo&q[][tag]=prod&ignore[][pacticipant]=Bar&ignore[][pacticipant]=Waffle&ignore[][version]=1" }

          it "sets the pacticipants to ignore" do
            expect(subject.last[:ignore_selectors]).to eq [
              PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "Bar"),
              PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "Waffle", pacticipant_version_number: "1")
            ]
          end
        end

        context "when the ignored selectors isn't a hash" do
          let(:query) { "q[][pacticipant]=Foo&q[][tag]=prod&ignore=1" }

          it "sets an empty array" do
            expect(subject.last[:ignore_selectors]).to eq []
          end
        end
      end
    end
  end
end
