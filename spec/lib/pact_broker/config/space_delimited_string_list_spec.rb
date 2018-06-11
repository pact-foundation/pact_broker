require 'pact_broker/config/space_delimited_string_list'

module PactBroker
  module Config
    describe SpaceDelimitedStringList do
      describe "parse" do
        subject { SpaceDelimitedStringList.parse(input) }

        context "when input is ''" do
          let(:input) { "" }

          it { is_expected.to eq [] }

          its(:to_s) { is_expected.to eq input }
        end

        context "when input is 'foo bar'" do
          let(:input) { "foo bar" }

          it { is_expected.to eq ["foo", "bar"] }

          it { is_expected.to be_a SpaceDelimitedStringList }

          its(:to_s) { is_expected.to eq input }
        end

        context "when input is '/foo.*/'" do
          let(:input) { "/foo.*/" }

          it { is_expected.to eq [/foo.*/] }

          its(:to_s) { is_expected.to eq input }
        end

        context "when input is '/foo\\.*/' (note double backslash)" do
          let(:input) { "/foo\\.*/" }

          it { is_expected.to eq [/foo\.*/] }

          its(:to_s) { is_expected.to eq input }
        end
      end
    end
  end
end
