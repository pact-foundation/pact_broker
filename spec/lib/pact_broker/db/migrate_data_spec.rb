require "pact_broker/db/migrate_data"

RSpec.describe PactBroker::DB::MigrateData do
  let(:database_connection) { double("Database Connection") }
  let(:options) { {} }
  let(:logger) { double("debug") }

  before do
    allow(PactBroker::DB::MigrateData).to receive(:logger).and_return(logger)
    described_class.registered_migrations.each do |migration|
      allow(migration).to receive(:call)
    end
  end

  describe ".call" do
    it "calls each data migration with the correct database connection" do
      allow(logger).to receive(:debug)
      described_class.call(database_connection, options)

      described_class.registered_migrations.each do |migration|
        expect(migration).to have_received(:call).with(database_connection)
      end
    end
      
    it "logs the name of each data migration" do
      described_class.registered_migrations.each do |migration|
        expect(logger).to receive(:debug).once.with("Running data migration #{migration.to_s.split("::").last.gsub(/([a-z\d])([A-Z])/, '\1 \2').split.join("-")}")
      end
      described_class.call(database_connection, options)

    end
  end
end

