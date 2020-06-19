require 'pact_broker/db/log_quietener'

module PactBroker
  module DB
    describe Logger do
      let(:logs) { StringIO.new }
      let(:wrapped_logger) { ::Logger.new(logs) }

      subject { LogQuietener.new(wrapped_logger) }

      describe "error" do
        context "when the error is for a table or view that does not exist" do
          before do
            subject.error("PG::UndefinedTable - some error")
          end

          it "logs the message at debug level" do
            expect(logs.string).to include "DEBUG -- :"
          end

          it "appends a friendly message so people don't freak out" do
            expect(logs.string).to include "PG::UndefinedTable - some error Don't panic."
          end
        end

        context "when the error is a foreign key constraint violation" do
          before do
            subject.error("SQLite3::ConstraintException: FOREIGN KEY constraint failed: delete from pacticipants where id = 1")
          end

          it "logs the message at warn level" do
            expect(logs.string).to include "WARN -- :"
          end
        end

        context "when the error is NOT for a table or view that does not exist" do
          before do
            subject.error("foo bar")
          end

          it "logs the message at error level" do
            expect(logs.string).to include "ERROR -- :"
          end

          it "does not appends a friendly message so people will correctly panic" do
            expect(logs.string).to_not include "Don't panic."
          end
        end
      end
    end
  end
end
