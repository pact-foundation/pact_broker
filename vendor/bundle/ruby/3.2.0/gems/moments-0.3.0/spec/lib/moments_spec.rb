# frozen_string_literal: true

require 'timecop'

describe Moments do
  describe '#difference' do
    subject { Moments.difference(from, to) }

    let(:from) { Time.new 2012, 1, 1 }
    let(:to)   { Time.new 2013, 1, 1 }

    it { is_expected.to be_a Moments::Difference }
  end

  describe '#ago' do
    subject { Moments.ago(from) }

    before do
      Timecop.freeze(to)
    end

    after do
      Timecop.return
    end

    let(:from) { Time.utc 2010, 1, 1, 0, 0, 0 }
    let(:to)   { Time.utc 2016, 6, 5, 3, 2, 1 }

    it { is_expected.to be_a Moments::Difference }

    context '#to_hash' do

      subject { Moments.ago(from).to_hash }
      let (:expected_result) do
        {
          years: 6,
          months: 5,
          days: 4,
          hours: 3,
          minutes: 2,
          seconds: 1
        }
      end

      it { is_expected.to eq expected_result}
    end

  end
end
