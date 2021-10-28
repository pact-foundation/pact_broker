require "pact_broker/db/clean/selector"

module PactBroker
  module DB
    class Clean
      describe Selector do
        describe ".from_hash" do
          subject { described_class.from_hash(data) }
          let(:data) { {} }
          context "with max_age" do
            let(:data) { {"max_age" => "20"} }

            it "parses integers" do
              expect(subject.max_age).to eq(20)
            end

            context "with unexpected value" do
              let(:data) { {"max_age" => "foobar"} }

              it "raises argument error" do
                expect { subject }.to raise_error(ArgumentError)
              end
            end
          end
        end
      end
    end
  end
end
