require "pact_broker/config/runtime_configuration_logging_methods"

module PactBroker
  module Config
    describe RuntimeConfigurationLoggingMethods do
      let(:string_io) { StringIO.new }
      let(:logger) { Logger.new(string_io) }
      let(:initial_values) { { database_password: "foo", database_url: "protocol://username:password@host/database"} }
      let(:runtime_configuration) { RuntimeConfiguration.new(initial_values) }

      subject do
        runtime_configuration.log_configuration(logger)
        string_io.string
      end

      it "redacts the sensitive values" do
        expect(subject).to include "database_password=*****"
        expect(subject).to include "database_url=protocol://username:*****@host/database"
      end

      it "logs values that don't have an initial default, but get set afterward" do
        expect(subject).to include "webhook_certificates=[] source={:type=>:defaults}"
      end

      context "with a database URL with no password" do
        let(:initial_values) { { database_password: "foo", database_url: "sqlite:///pact_broker.sqlite3" } }

        it "maintians the specified value" do
          expect(subject).to include "database_url=sqlite:///pact_broker.sqlite3"
        end
      end
    end
  end
end
