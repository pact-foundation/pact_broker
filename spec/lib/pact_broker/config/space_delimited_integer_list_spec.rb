require 'pact_broker/config/space_delimited_integer_list'

module PactBroker
  module Config
    describe SpaceDelimitedIntegerList do
      describe "parse" do
        subject { SpaceDelimitedIntegerList.parse(input) }

        context "when input is ''" do
          let(:input) { "" }

          it { is_expected.to eq [] }
          it { is_expected.to be_a SpaceDelimitedIntegerList }

          its(:to_s) { is_expected.to eq input }
        end

        context "when input is 'off'" do
          let(:input) { "off" }

          it { is_expected.to eq [] }
          it { is_expected.to be_a SpaceDelimitedIntegerList }

          its(:to_s) { is_expected.to eq "" }
        end

        context "when input is '0 1 1 2 3 5 8 13 21 34'" do
          let(:input) { "0 1 1 2 3 5 8 13 21 34" }

          it { is_expected.to eq [0, 1, 1, 2, 3, 5, 8, 13, 21, 34] }
          it { is_expected.to be_a SpaceDelimitedIntegerList }

          its(:to_s) { is_expected.to eq input }
        end

        context "when input is '13 17 foo 19'" do
          let(:input) { "13 17 foo 19" }

          it { is_expected.to eq [13, 17, 19] }
          it { is_expected.to be_a SpaceDelimitedIntegerList }

          its(:to_s) { is_expected.to eq "13 17 19" }
        end
      end
    end
  end
end
