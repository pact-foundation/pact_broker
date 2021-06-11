require "sequel/plugins/insert_ignore"
require "sequel"

module Sequel
  module Plugins
    module InsertIgnore
      class PacticipantNoInsertIgnore < Sequel::Model(:pacticipants)
        plugin :timestamps, update_on_create: true
      end

      class Pacticipant < Sequel::Model
        plugin :insert_ignore, identifying_columns: [:name]
        plugin :timestamps, update_on_create: true
      end

      class Version < Sequel::Model
        plugin :insert_ignore, identifying_columns: [:pacticipant_id, :number]
        plugin :timestamps, update_on_create: true
      end

      context "when a duplicate is inserted with no insert_ignore" do
        before do
          PacticipantNoInsertIgnore.new(name: "Foo").save
        end

        subject do
          PacticipantNoInsertIgnore.new(name: "Foo").save
        end

        it "raises an error" do
          expect { subject }.to raise_error Sequel::UniqueConstraintViolation
        end
      end

      # This doesn't work on MSQL because the _insert_raw method
      # does not return the row ID of the duplicated row when insert_ignore is used
      # May have to go back to the old method of doing this
      context "when a duplicate Pacticipant is inserted with insert_ignore" do
        before do
          Pacticipant.new(name: "Foo", repository_url: "http://foo").insert_ignore
        end

        subject do
          Pacticipant.new(name: "Foo").insert_ignore
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end

        it "sets the values on the object" do
          expect(subject.repository_url).to eq "http://foo"
        end

        it "does not insert another row" do
          expect { subject }.to_not change { Pacticipant.count }
        end
      end

      context "when a duplicate Version is inserted with insert_ignore" do
        let!(:pacticipant) { Pacticipant.new(name: "Foo").save }
        let!(:original_version) { Version.new(number: "1", pacticipant_id: pacticipant.id).insert_ignore }

        subject do
          Version.new(number: "1", pacticipant_id: pacticipant.id).insert_ignore
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end

        it "sets the values on the object" do
          expect(subject.id).to eq original_version.id
        end

        it "does not insert another row" do
          expect { subject }.to_not change { Version.count }
        end
      end
    end
  end
end
