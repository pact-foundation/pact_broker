require 'pact_broker/db/insert_ignore'
require 'sequel'
# require 'method_source'

module PactBroker
  module DB
    module InsertIgnore

      class PacticipantInsertIgnore < Sequel::Model(:pacticipants)
        include InsertIgnore
        plugin :timestamps, update_on_create: true
      end

      class Pacticipant < Sequel::Model
        plugin :timestamps, update_on_create: true
      end

      context "when a duplicate is inserted with no insert_ignore" do
        before do
          Pacticipant.new(name: "Foo").save
        end

        subject do
          Pacticipant.new(name: "Foo").save
        end

        it "raises an error" do
          expect { subject }.to raise_error Sequel::UniqueConstraintViolation
        end
      end

      # This doesn't work on MSQL because the _insert_raw method
      # does not return the row ID of the duplicated row when insert_ignore is used
      # May have to go back to the old method of doing this
      context "when a duplicate is inserted with insert_ignore", skip: DB.mysql? do
        before do
          PacticipantInsertIgnore.new(name: "Foo").save
        end

        subject do
          PacticipantInsertIgnore.new(name: "Foo").save
        end

        it "does not raise an error" do
          expect { subject }.to_not raise_error
        end

        it "does not insert another row" do
          expect { subject }.to_not change { PacticipantInsertIgnore.count }
        end
      end

      # describe "#_insert_dataset" do
      #   it "naughtily overrides a private method, and this test ensures that we know exactly what we're overriding" do
      #     insert_raw = Sequel::Model.instance_method(:_insert_dataset)
      #     insert_raw.instance_eval do
      #       extend MethodSource::MethodExtensions
      #     end
      #     expect(insert_raw.source).to eq "      def _insert_dataset\n        use_server(model.instance_dataset)\n      end\n"
      #   end
      # end
    end
  end
end
