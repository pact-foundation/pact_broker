require 'pact_broker/db/clean'
require 'pact_broker/matrix/unresolved_selector'

IS_MYSQL = !!DB.mysql?

module PactBroker
  module DB
    # Inner queries don't work on MySQL. Seriously, MySQL???
    describe Clean, pending: IS_MYSQL  do
      let(:options) { {} }
      let(:db) { PactBroker::DB.connection }

      subject { Clean.call(PactBroker::DB.connection, options) }

      describe ".call"do
        context "when there are specified versions to keep" do
          before do
            td.create_pact_with_hierarchy("Foo", "1", "Bar")
              .create_consumer_version_tag("prod")
              .create_consumer_version_tag("master")
              .create_consumer_version("3", tag_names: %w{prod})
              .create_pact
              .create_consumer_version("4", tag_names: %w{master})
              .create_pact
              .create_consumer_version("5", tag_names: %w{master})
              .create_pact
              .create_consumer_version("6", tag_names: %w{foo})
              .create_pact
          end

          let(:options) do
            {
              keep: [
                PactBroker::Matrix::UnresolvedSelector.new(tag: "prod"),
                PactBroker::Matrix::UnresolvedSelector.new(tag: "master", latest: true)
              ]
            }
          end

          it "does not delete the consumer versions specified" do
            expect(PactBroker::Domain::Version.where(number: "1").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "3").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "4").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "5").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "6").count).to be 1
            subject
            expect(PactBroker::Domain::Version.where(number: "1").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "3").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "4").count).to be 0
            expect(PactBroker::Domain::Version.where(number: "5").count).to be 1
            expect(PactBroker::Domain::Version.where(number: "6").count).to be 0
          end
        end
      end
    end
  end
end
