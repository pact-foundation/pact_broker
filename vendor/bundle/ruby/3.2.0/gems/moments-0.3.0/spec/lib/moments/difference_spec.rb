# frozen_string_literal: true

describe Moments::Difference do
  let(:from) { Time.utc 2007, 1, 1 }
  let(:to)   { Time.utc 2012, 1, 1 }

  describe '#new' do
    context 'without arguments' do
      it { expect { Moments::Difference.new }.to raise_error(ArgumentError) }
    end
  end

  context '#to_hash' do
    subject { Moments::Difference.new(from, to).to_hash }

    describe 'order of keys' do
      subject { super().keys }

      it { is_expected.to eq %i[years months days hours minutes seconds] }
    end

    context 'with equal dates' do
      let(:to) { from }

      let(:expected_result) do
        {
          years: 0,
          months: 0,
          days: 0,
          hours: 0,
          minutes: 0,
          seconds: 0
        }
      end

      it { is_expected.to eq expected_result }
    end

    describe 'seconds' do
      let(:expected_result) do
        {
          years: 0,
          months: 0,
          days: 0,
          hours: 0,
          minutes: 0,
          seconds: 1
        }
      end

      context 'when future' do
        context 'when the same minute' do
          let(:from) { Time.utc 2013, 1, 1, 0, 0, 0 }
          let(:to)   { Time.utc 2013, 1, 1, 0, 0, 1 }

          it { is_expected.to eq expected_result }
        end

        context 'when different minutes' do
          let(:from) { Time.utc 2013, 1, 31, 23, 59, 59 }
          let(:to)   { Time.utc 2013, 2, 1, 0, 0, 0 }

          it { is_expected.to eq expected_result }
        end
      end

      context 'when past' do
        context 'when the same minute' do
          let(:from) { Time.utc 2013, 1, 1, 0, 0, 1 }
          let(:to)   { Time.utc 2013, 1, 1, 0, 0, 0 }

          it { is_expected.to eq expected_result }
        end

        context 'when different minutes' do
          let(:from) { Time.utc 2013, 2, 1, 0, 0, 0 }
          let(:to)   { Time.utc 2013, 1, 31, 23, 59, 59 }

          it { is_expected.to eq expected_result }
        end
      end
    end

    describe 'minutes' do
      let(:expected_result) do
        {
          years: 0,
          months: 0,
          days: 0,
          hours: 0,
          minutes: 2,
          seconds: 1
        }
      end

      context 'when future' do
        context 'when the same hour' do
          let(:from) { Time.utc 2013, 1, 1, 0, 0, 0 }
          let(:to)   { Time.utc 2013, 1, 1, 0, 2, 1 }

          it { is_expected.to eq expected_result }
        end

        context 'when different hours' do
          let(:from) { Time.utc 2013, 1, 31, 23, 59, 59 }
          let(:to)   { Time.utc 2013, 2, 1, 0, 2, 0 }

          it { is_expected.to eq expected_result }
        end
      end

      context 'when past' do
        context 'when the same hour' do
          let(:from) { Time.utc 2013, 1, 1, 0, 2, 1 }
          let(:to)   { Time.utc 2013, 1, 1, 0, 0, 0 }

          it { is_expected.to eq expected_result }
        end

        context 'when different hours' do
          let(:from) { Time.utc 2013, 2, 1, 0, 2, 0 }
          let(:to)   { Time.utc 2013, 1, 31, 23, 59, 59 }

          it { is_expected.to eq expected_result }
        end
      end
    end

    describe 'hours' do
      let(:expected_result) do
        {
          years: 0,
          months: 0,
          days: 0,
          hours: 3,
          minutes: 2,
          seconds: 1
        }
      end

      context 'when future' do
        context 'when the same day' do
          let(:from) { Time.utc 2013, 1, 1, 0, 0, 0 }
          let(:to)   { Time.utc 2013, 1, 1, 3, 2, 1 }

          it { is_expected.to eq expected_result }
        end

        context 'when different days' do
          let(:from) { Time.utc 2013, 1, 31, 23, 59, 59 }
          let(:to)   { Time.utc 2013, 2, 1, 3, 2, 0 }

          it { is_expected.to eq expected_result }
        end
      end

      context 'when past' do
        context 'when the same day' do
          let(:from) { Time.utc 2013, 1, 1, 3, 2, 1 }
          let(:to)   { Time.utc 2013, 1, 1, 0, 0, 0 }

          it { is_expected.to eq expected_result }
        end

        context 'when different days' do
          let(:from) { Time.utc 2013, 2, 1, 3, 2, 0 }
          let(:to)   { Time.utc 2013, 1, 31, 23, 59, 59 }

          it { is_expected.to eq expected_result }
        end
      end
    end

    describe 'days' do
      let(:expected_result) do
        {
          years: 0,
          months: 0,
          days: 4,
          hours: 3,
          minutes: 2,
          seconds: 1
        }
      end

      context 'when future' do
        context 'when the same month' do
          let(:from) { Time.utc 2013, 1, 1, 0, 0, 0 }
          let(:to)   { Time.utc 2013, 1, 5, 3, 2, 1 }

          it { is_expected.to eq expected_result }
        end

        context 'when different months' do
          let(:from) { Time.utc 2013, 1, 31, 23, 59, 59 }
          let(:to)   { Time.utc 2013, 2, 5, 3, 2, 0 }

          it { is_expected.to eq expected_result }
        end

        context 'when `to` month has a fewer days than `from`' do
          let(:from) { Time.utc 2013, 1, 31, 3, 2, 0 }
          let(:to)   { Time.utc 2013, 2, 28, 23, 59, 59 }

          let(:expected_result) do
            {
              years: 0,
              months: 0,
              days: 28,
              hours: 20,
              minutes: 57,
              seconds: 59
            }
          end

          it { is_expected.to eq expected_result }
        end
      end

      context 'when past' do
        context 'when the same month' do
          let(:from) { Time.utc 2013, 1, 5, 3, 2, 1 }
          let(:to)   { Time.utc 2013, 1, 1, 0, 0, 0 }

          it { is_expected.to eq expected_result }
        end

        context 'when different months' do
          let(:from) { Time.utc 2013, 2, 5, 3, 2, 0 }
          let(:to)   { Time.utc 2013, 1, 31, 23, 59, 59 }

          it { is_expected.to eq expected_result }
        end
      end
    end

    describe 'months' do
      let(:expected_result) do
        {
          years: 0,
          months: 5,
          days: 4,
          hours: 3,
          minutes: 2,
          seconds: 1
        }
      end

      context 'when future' do
        context 'when the same year' do
          let(:from) { Time.utc 2013, 1, 1, 0, 0, 0 }
          let(:to)   { Time.utc 2013, 6, 5, 3, 2, 1 }

          it { is_expected.to eq expected_result }
        end

        context 'when different years' do
          let(:from) { Time.utc 2012, 8, 27, 20, 57, 58 }
          let(:to)   { Time.utc 2013, 1, 31, 23, 59, 59 }

          it { is_expected.to eq expected_result }
        end
      end

      context 'when past' do
        context 'when the same year' do
          let(:from) { Time.utc 2013, 6, 5, 3, 2, 1 }
          let(:to)   { Time.utc 2013, 1, 1, 0, 0, 0 }

          it { is_expected.to eq expected_result }
        end

        context 'when different years' do
          let(:from) { Time.utc 2013, 1, 31, 23, 59, 59 }
          let(:to)   { Time.utc 2012, 8, 27, 20, 57, 58 }

          it { is_expected.to eq expected_result }
        end
      end
    end

    describe 'years' do
      let(:expected_result) do
        {
          years: 6,
          months: 5,
          days: 4,
          hours: 3,
          minutes: 2,
          seconds: 1
        }
      end

      context 'when future' do
        let(:from) { Time.utc 2013, 1, 1, 0, 0, 0 }
        let(:to)   { Time.utc 2019, 6, 5, 3, 2, 1 }

        it { is_expected.to eq expected_result }
      end

      context 'when past' do
        let(:from) { Time.utc 2019, 6, 5, 3, 2, 1 }
        let(:to)   { Time.utc 2013, 1, 1, 0, 0, 0 }

        it { is_expected.to eq expected_result }
      end

      context 'when different time zones' do
        let(:from) { Time.new 2013, 1, 1, 3, 0, 0, '+03:00' }
        let(:to)   { Time.new 2019, 6, 5, 3, 2, 1, '+00:00' }

        it { is_expected.to eq expected_result }
      end

      context 'with DateTime class' do
        context 'when future' do
          let(:from) { DateTime.new 2013, 1, 1, 0, 0, 0 }
          let(:to)   { DateTime.new 2019, 6, 5, 3, 2, 1 }

          it { is_expected.to eq expected_result }
        end

        context 'when past' do
          let(:from) { DateTime.new 2019, 6, 5, 3, 2, 1 }
          let(:to)   { DateTime.new 2013, 1, 1, 0, 0, 0 }

          it { is_expected.to eq expected_result }
        end
      end

      context 'with Date class' do
        let(:expected_result) do
          {
            years: 6,
            months: 5,
            days: 4,
            hours: 0,
            minutes: 0,
            seconds: 0
          }
        end

        context 'when future' do
          let(:from) { Date.new 2013, 1, 1 }
          let(:to)   { Date.new 2019, 6, 5 }

          it { is_expected.to eq expected_result }
        end

        context 'when past' do
          let(:from) { Date.new 2019, 6, 5 }
          let(:to)   { Date.new 2013, 1, 1 }

          it { is_expected.to eq expected_result }
        end
      end
    end

    context 'leap year' do
      let(:expected_result) do
        {
          years: 0,
          months: 0,
          days: 2,
          hours: 0,
          minutes: 0,
          seconds: 0
        }
      end

      let(:from) { Time.utc 2008, 2, 28 }
      let(:to)   { Time.utc 2008, 3, 1 }

      it { is_expected.to eq expected_result }
    end
  end

  describe '#same?' do
    subject { Moments::Difference.new(from, to).same? }

    context 'with the same dates' do
      let(:to) { from }

      it { is_expected.to eq true }
    end

    context 'when `from` is earlier than `to`' do
      let(:from) { Time.utc 2020, 1, 1 }
      let(:to)   { Time.utc 2020, 1, 2 }

      it { is_expected.to eq false }
    end

    context 'when `to` is earlier than `from`' do
      let(:from) { Time.utc 2020, 1, 2 }
      let(:to)   { Time.utc 2020, 1, 1 }

      it { is_expected.to eq false }
    end
  end

  describe '#future?' do
    subject { Moments::Difference.new(from, to).future? }

    context 'with the same dates' do
      let(:to) { from }

      it { is_expected.to eq false }
    end

    context 'when `from` is earlier than `to`' do
      let(:from) { Time.utc 2020, 1, 1 }
      let(:to)   { Time.utc 2020, 1, 2 }

      it { is_expected.to eq true }
    end

    context 'when `to` is earlier than `from`' do
      let(:from) { Time.utc 2020, 1, 2 }
      let(:to)   { Time.utc 2020, 1, 1 }

      it { is_expected.to eq false }
    end
  end

  describe '#past?' do
    subject { Moments::Difference.new(from, to).past? }

    context 'with the same dates' do
      let(:to) { from }

      it { is_expected.to eq false }
    end

    context 'when `from` is earlier than `to`' do
      let(:from) { Time.utc 2020, 1, 1 }
      let(:to)   { Time.utc 2020, 1, 2 }

      it { is_expected.to eq false }
    end

    context 'when `to` is earlier than `from`' do
      let(:from) { Time.utc 2020, 1, 2 }
      let(:to)   { Time.utc 2020, 1, 1 }

      it { is_expected.to eq true }
    end
  end

  shared_examples 'in a component' do |when_seconds:, when_minutes:, when_hours:, when_days:, when_months:, when_years:|
    context 'with equal dates' do
      let(:to) { from }

      it { is_expected.to eq 0 }
    end

    context 'when seconds' do
      let(:expected_result) { when_seconds }

      context 'when future' do
        context 'when the same minute' do
          let(:from) { Time.utc 2013, 1, 1, 0, 0, 0 }
          let(:to)   { Time.utc 2013, 1, 1, 0, 0, 15 }

          it { is_expected.to eq expected_result }
        end

        context 'when different minutes' do
          let(:from) { Time.utc 2013, 1, 31, 23, 59, 59 }
          let(:to)   { Time.utc 2013, 2, 1, 0, 0, 14 }

          it { is_expected.to eq expected_result }
        end
      end

      context 'when past' do
        context 'when the same minute' do
          let(:from) { Time.utc 2013, 1, 1, 0, 0, 15 }
          let(:to)   { Time.utc 2013, 1, 1, 0, 0, 0 }

          it { is_expected.to eq expected_result }
        end

        context 'when different minutes' do
          let(:from) { Time.utc 2013, 2, 1, 0, 0, 14 }
          let(:to)   { Time.utc 2013, 1, 31, 23, 59, 59 }

          it { is_expected.to eq expected_result }
        end
      end
    end

    context 'when minutes' do
      let(:expected_result) { when_minutes }

      context 'when future' do
        context 'when the same hour' do
          let(:from) { Time.utc 2013, 1, 1, 0, 0, 0 }
          let(:to)   { Time.utc 2013, 1, 1, 0, 12, 15 }

          it { is_expected.to eq expected_result }
        end

        context 'when different hours' do
          let(:from) { Time.utc 2013, 1, 31, 23, 59, 59 }
          let(:to)   { Time.utc 2013, 2, 1, 0, 12, 14 }

          it { is_expected.to eq expected_result }
        end
      end

      context 'when past' do
        context 'when the same hour' do
          let(:from) { Time.utc 2013, 1, 1, 0, 12, 15 }
          let(:to)   { Time.utc 2013, 1, 1, 0, 0, 0 }

          it { is_expected.to eq expected_result }
        end

        context 'when different hours' do
          let(:from) { Time.utc 2013, 2, 1, 0, 12, 14 }
          let(:to)   { Time.utc 2013, 1, 31, 23, 59, 59 }

          it { is_expected.to eq expected_result }
        end
      end
    end

    context 'when hours' do
      let(:expected_result) { when_hours }

      context 'when future' do
        context 'when the same day' do
          let(:from) { Time.utc 2013, 1, 1, 0, 0, 0 }
          let(:to)   { Time.utc 2013, 1, 1, 8, 12, 15 }

          it { is_expected.to eq expected_result }
        end

        context 'when different days' do
          let(:from) { Time.utc 2013, 1, 31, 23, 59, 59 }
          let(:to)   { Time.utc 2013, 2, 1, 8, 12, 14 }

          it { is_expected.to eq expected_result }
        end
      end

      context 'when past' do
        context 'when the same day' do
          let(:from) { Time.utc 2013, 1, 1, 8, 12, 15 }
          let(:to)   { Time.utc 2013, 1, 1, 0, 0, 0 }

          it { is_expected.to eq expected_result }
        end

        context 'when different days' do
          let(:from) { Time.utc 2013, 2, 1, 8, 12, 14 }
          let(:to)   { Time.utc 2013, 1, 31, 23, 59, 59 }

          it { is_expected.to eq expected_result }
        end
      end
    end

    context 'when days' do
      let(:expected_result) { when_days }

      context 'when future' do
        context 'when the same month' do
          let(:from) { Time.utc 2013, 1, 1, 0, 0, 0 }
          let(:to)   { Time.utc 2013, 1, 7, 8, 12, 15 }

          it { is_expected.to eq expected_result }
        end

        context 'when different months' do
          let(:from) { Time.utc 2013, 1, 31, 23, 59, 59 }
          let(:to)   { Time.utc 2013, 2, 7, 8, 12, 14 }

          it { is_expected.to eq expected_result }
        end
      end

      context 'when past' do
        context 'when the same month' do
          let(:from) { Time.utc 2013, 1, 7, 8, 12, 15 }
          let(:to)   { Time.utc 2013, 1, 1, 0, 0, 0 }

          it { is_expected.to eq expected_result }
        end

        context 'when different months' do
          let(:from) { Time.utc 2013, 2, 7, 8, 12, 14 }
          let(:to)   { Time.utc 2013, 1, 31, 23, 59, 59 }

          it { is_expected.to eq expected_result }
        end
      end
    end

    describe 'when months' do
      let(:expected_result) { when_months }

      context 'when future' do
        context 'when the same year' do
          let(:from) { Time.utc 2013, 1, 1, 0, 0, 0 }
          let(:to)   { Time.utc 2013, 5, 7, 8, 12, 15 }

          it { is_expected.to eq expected_result }
        end

        context 'when different years' do
          let(:from) { Time.utc 2013, 1, 31, 23, 59, 59 }
          let(:to)   { Time.utc 2013, 6, 7, 8, 12, 14 }

          it { is_expected.to eq expected_result }
        end
      end

      context 'when past' do
        context 'when the same year' do
          let(:from) { Time.utc 2013, 5, 7, 8, 12, 15 }
          let(:to)   { Time.utc 2013, 1, 1, 0, 0, 0 }

          it { is_expected.to eq expected_result }
        end

        context 'when different years' do
          let(:from) { Time.utc 2013, 6, 7, 8, 12, 14 }
          let(:to)   { Time.utc 2013, 1, 31, 23, 59, 59 }

          it { is_expected.to eq expected_result }
        end
      end
    end

    context 'when years' do
      let(:expected_result) { when_years }

      context 'when future' do
        let(:from) { Time.utc 2013, 1, 1, 0, 0, 0 }
        let(:to)   { Time.utc 2015, 5, 7, 8, 12, 15 }

        it { is_expected.to eq expected_result }

        context 'with DateTime class' do
          let(:from) { DateTime.new 2013, 1, 1, 0, 0, 0 }
          let(:to)   { DateTime.new 2015, 5, 7, 8, 12, 15 }

          it { is_expected.to eq expected_result }
        end
      end

      context 'when past' do
        let(:from) { Time.utc 2015, 5, 7, 8, 12, 15 }
        let(:to)   { Time.utc 2013, 1, 1, 0, 0, 0 }

        it { is_expected.to eq expected_result }
      end
    end
  end

  context '#in_seconds' do
    subject { Moments::Difference.new(from, to).in_seconds }

    include_examples 'in a component',
                     when_seconds: 15,
                     when_minutes: (12 * 60) + 15,
                     when_hours: (8 * 60 * 60) + (12 * 60) + 15,
                     when_days: (6 * 24 * 60 * 60) + (8 * 60 * 60) + (12 * 60) + 15,
                     when_months:
                       ((31 + 28 + 31 + 30) * 24 * 60 * 60) +
                         (6 * 24 * 60 * 60) +
                         (8 * 60 * 60) +
                         (12 * 60) +
                         15,
                     when_years:
                       (2 * 365 * 24 * 60 * 60) +
                         ((31 + 28 + 31 + 30) * 24 * 60 * 60) +
                         (6 * 24 * 60 * 60) +
                         (8 * 60 * 60) +
                         (12 * 60) +
                         15

    context 'with miliseconds' do
      context 'when `to` is a bit greater' do
        let(:from) { Time.utc(2020, 7, 11, 20, 26, 12) }
        let(:to)   { Time.utc(2020, 7, 11, 20, 28, 39.149092) }

        it { is_expected.to eq 147 }
      end

      context 'when `from` is a bit greater' do
        let(:from) { Time.utc(2020, 7, 11, 20, 26, 12.149092) }
        let(:to)   { Time.utc(2020, 7, 11, 20, 28, 39) }

        it { is_expected.to eq 147 }
      end

      context 'when `to` is a lot greater' do
        let(:from) { Time.utc(2020, 7, 11, 20, 26, 12) }
        let(:to)   { Time.utc(2020, 7, 11, 20, 28, 39.896152) }

        it { is_expected.to eq 147 }
      end

      context 'when `from` is a lot greater' do
        let(:from) { Time.utc(2020, 7, 11, 20, 26, 12.896152) }
        let(:to)   { Time.utc(2020, 7, 11, 20, 28, 39) }

        it { is_expected.to eq 147 }
      end
    end
  end

  context '#in_minutes' do
    subject { Moments::Difference.new(from, to).in_minutes }

    include_examples 'in a component',
                     when_seconds: 0,
                     when_minutes: 12,
                     when_hours: (8 * 60) + 12,
                     when_days: (6 * 24 * 60) + (8 * 60) + 12,
                     when_months:
                       ((31 + 28 + 31 + 30) * 24 * 60) +
                         (6 * 24 * 60) +
                         (8 * 60) +
                         12,
                     when_years:
                       (2 * 365 * 24 * 60) +
                         ((31 + 28 + 31 + 30) * 24 * 60) +
                         (6 * 24 * 60) +
                         (8 * 60) +
                         12
  end

  context '#in_hours' do
    subject { Moments::Difference.new(from, to).in_hours }

    include_examples 'in a component',
                     when_seconds: 0,
                     when_minutes: 0,
                     when_hours: 8,
                     when_days: (6 * 24) + 8,
                     when_months:
                       ((31 + 28 + 31 + 30) * 24) +
                         (6 * 24) +
                         8,
                     when_years:
                       (2 * 365 * 24) +
                         ((31 + 28 + 31 + 30) * 24) +
                         (6 * 24) +
                         8
  end

  context '#in_days' do
    subject { Moments::Difference.new(from, to).in_days }

    include_examples 'in a component',
                     when_seconds: 0,
                     when_minutes: 0,
                     when_hours: 0,
                     when_days: 6,
                     when_months:
                       (31 + 28 + 31 + 30) +
                         6,
                     when_years:
                       (2 * 365) +
                         (31 + 28 + 31 + 30) +
                         6
  end

  context '#in_months' do
    subject { Moments::Difference.new(from, to).in_months }

    include_examples 'in a component',
                     when_seconds: 0,
                     when_minutes: 0,
                     when_hours: 0,
                     when_days: 0,
                     when_months: 4,
                     when_years: (2 * 12) + 4
  end

  context '#in_years' do
    subject { Moments::Difference.new(from, to).in_years }

    include_examples 'in a component',
                     when_seconds: 0,
                     when_minutes: 0,
                     when_hours: 0,
                     when_days: 0,
                     when_months: 0,
                     when_years: 2

    context 'when `to` day is greater than `from` day' do
      let(:from) { Time.utc 2013, 1, 1, 0, 0, 0 }
      let(:to)   { Time.utc 2015, 1, 7, 8, 12, 15 }

      it { is_expected.to eq 2 }
    end

    context 'when `to` day is less than `from` day' do
      let(:from) { Time.utc 2013, 1, 7, 0, 0, 0 }
      let(:to)   { Time.utc 2015, 1, 1, 8, 12, 15 }

      it { is_expected.to eq 1 }
    end
  end

  context '#humanized' do
    subject { Moments::Difference.new(from, to).humanized }

    let (:from) { Time.utc 2020, 1, 1, 0, 0, 0 }

    {
      [2021, 1, 1, 0, 0, 0] => '1 year',
      [2020, 2, 1, 0, 0, 0] => '1 month',
      [2020, 1, 2, 0, 0, 0] => '1 day',
      [2020, 1, 1, 1, 0, 0] => '1 hour',
      [2020, 1, 1, 0, 1, 0] => '1 minute',
      [2020, 1, 1, 0, 0, 1] => '1 second',
      [2022, 1, 1, 0, 0, 0] => '2 years',
      [2020, 4, 1, 0, 0, 0] => '3 months',
      [2020, 1, 5, 0, 0, 0] => '4 days',
      [2020, 1, 1, 5, 0, 0] => '5 hours',
      [2020, 1, 1, 0, 6, 0] => '6 minutes',
      [2020, 1, 1, 0, 0, 7] => '7 seconds',
      [2021, 2, 1, 0, 0, 0] => '1 year and 1 month',
      [2021, 1, 2, 0, 0, 0] => '1 year and 1 day',
      [2021, 1, 1, 1, 0, 0] => '1 year and 1 hour',
      [2021, 1, 1, 0, 1, 0] => '1 year and 1 minute',
      [2021, 1, 1, 0, 0, 1] => '1 year and 1 second',
      [2021, 2, 2, 0, 0, 0] => '1 year, 1 month and 1 day',
      [2021, 2, 1, 1, 0, 0] => '1 year, 1 month and 1 hour',
      [2022, 4, 5, 5, 6, 7] => '2 years, 3 months, 4 days, 5 hours, 6 minutes and 7 seconds'
    }.each do |time_array, string|
      context "with #{string}" do
        let (:to) { Time.utc *time_array }

        it { is_expected.to eq string}
      end
    end
  end
end
