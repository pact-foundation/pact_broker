require "pact_broker/api/decorators/format_date_time"

module PactBroker
  module Api
    module Decorators
      module FormatDateTime
        describe ".call" do
          context "with a Time object" do
            let(:date_time) { Time.parse("2022-02-14T15:18:00+14:00" )}

            it "converts the date to a string in utc" do
              expect(FormatDateTime.call(date_time)).to eq "2022-02-14T01:18:00+00:00"
            end
          end

          context "with a DateTime object" do
            let(:date_time) { DateTime.parse("2022-02-14T15:18:00+14:00" )}

            it "converts the date to a string in utc" do
              expect(FormatDateTime.call(date_time)).to eq "2022-02-14T01:18:00+00:00"
            end
          end

          context "with a String - MySQL and Sqlite (as of the upgrade to Ruby 2.7.5) return date columns as strings. Postgres returns them as dates." do
            let(:date_time) { "2022-02-14T15:18:00+14:00" }

            it "converts the date to a string in utc" do
              expect(FormatDateTime.call(date_time)).to eq "2022-02-14T01:18:00+00:00"
            end
          end
        end
      end
    end
  end
end
