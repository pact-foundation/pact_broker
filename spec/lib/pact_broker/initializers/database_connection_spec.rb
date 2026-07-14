require "pact_broker/initializers/database_connection"
require "pact_broker/error"

module PactBroker
  describe ".create_database_connection" do
    context "when the adapter is a mysql adapter" do
      it "raises a friendly error instead of attempting to connect" do
        expect {
          PactBroker.create_database_connection(adapter: "mysql2", database: "pact_broker")
        }.to raise_error(PactBroker::Error, /MySQL is no longer supported/)
      end
    end
  end
end
