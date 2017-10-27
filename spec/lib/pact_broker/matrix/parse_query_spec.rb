require 'pact_broker/matrix/parse_query'

module PactBroker
  module Matrix
    describe ParseQuery do
      describe ".call" do
        let(:query) { "q[][pacticipant]=Foo&q[][version]=1.2.3&q[][pacticipant]=Bar&q[][version]=9.9.9" }

        subject { ParseQuery.call(query) }

        it "extracts the pacticipant names and respective versions" do
          expect(subject).to eq "Foo" => "1.2.3", "Bar" => "9.9.9"
        end

        context "with spaces" do
          let(:query) { "q[][pacticipant]=Name%20With%20Spaces&q[][version]=1%202" }

          it "works" do
            expect(subject).to eq "Name With Spaces" => "1 2"
          end
        end

        context "with no q" do
          let(:query) { "foo" }

          it "returns an empty hash" do
            expect(subject).to eq({})
          end
        end

        context "with an incorrect param names" do
          let(:query) { "q[][wrong]=Foo&q[][blah]=1.2.3" }

          it "returns nil keys or values" do
            expect(subject).to eq nil => nil
          end
        end
      end
    end
  end
end
