require 'pact_broker/matrix/parse_query'

module PactBroker
  module Matrix
    describe ParseQuery do
      describe ".call" do
        let(:query) { "q[][pacticipant]=Foo&q[][version]=1.2.3&q[][pacticipant]=Bar&q[][version]=9.9.9" }

        subject { ParseQuery.call(query) }

        it "extracts the pacticipant names and respective versions" do
          expect(subject.first).to eq([{ pacticipant_name: "Foo", pacticipant_version_number: "1.2.3" }, { pacticipant_name: "Bar", pacticipant_version_number: "9.9.9" }])
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
            expect(subject.first).to eq [{ pacticipant_name: nil, pacticipant_version_number: nil }]
          end
        end

        context "with no options specified" do
          let(:query) { "" }

          it "does not set any options" do
            expect(subject.last).to eq({})
          end
        end

        context "with just one status specified" do
          let(:query) { "success=true" }
          it "extracts the one status" do
            expect(subject.last).to eq success: [true]
          end
        end

        context "with an array of statuses" do
          let(:query) { "success[]=true&success[]=false&success[]=" }
          it "extracts the statuses" do
            expect(subject.last).to eq success: [true, false, nil]
          end
        end

        context "with success[]=" do
          let(:query) { "success[]=&foo=bar" }

          it "sets an array with a nil success" do
            expect(subject.last).to eq(success: [nil])
          end
        end

        context "with success=" do
          let(:query) { "success=&foo=bar" }

          it "sets an array with a nil success" do
            expect(subject.last).to eq(success: [nil])
          end
        end
      end
    end
  end
end
