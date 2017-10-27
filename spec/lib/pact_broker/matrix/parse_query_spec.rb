require 'pact_broker/matrix/parse_query'

module PactBroker
  module Matrix
    describe ParseQuery do
      describe ".call" do
        let(:query) { "pacticipant[]=Foo&pacticipant[]=Bar&version[]=1.2.3&version[]=9.9.9" }

        subject { ParseQuery.call(query) }

        it "extracts the pacticipant names and respective versions" do
          expect(subject).to eq "Foo" => "1.2.3", "Bar" => "9.9.9"
        end

        context "with spaces" do
          let(:query) { "pacticipant%5B%5D=Name%20With%20Spaces&version%5B%5D=1%202" }

          it "works" do
            expect(subject).to eq "Name With Spaces" => "1 2"
          end
        end
      end
    end
  end
end
