require "sequel/plugins/age"
require "timecop"
require "tzinfo"

module Sequel
  module Plugins
    module Age
      class TestPacticipant < Sequel::Model(:pacticipants)
        plugin :timestamps, update_on_create: true
        plugin :age
      end

      describe "#age" do
        after do
          Timecop.return
        end

        it "returns the age of the model as the time since the created_at date" do
          Timecop.freeze(Time.new(2021, 9, 1, 10, 7, 21, TZInfo::Timezone.get("Australia/Melbourne")))
          pacticipant = TestPacticipant.create(name: "Foo")
          Timecop.freeze(Time.new(2021, 9, 1, 10, 8, 21, TZInfo::Timezone.get("Australia/Melbourne")))
          expect(pacticipant.age.in_minutes).to eq 1
        end
      end
    end
  end
end
