require "pact_broker/domain/pacticipant"

module PactBroker
  module Domain
    describe Pacticipant do
      describe "#latest_version" do
        before do
          td.create_consumer("Foo")
            .create_consumer_version("1")
            .create_consumer_version("2")
            .create_consumer_version("3")
            .create_consumer("Bar")
            .create_consumer_version("10")
            .create_consumer_version("11")
            .create_consumer_version("12")
        end

        it "lazy loads" do
          pacticipants = Pacticipant.order(:id).all
          expect(pacticipants.first.latest_version.number).to eq "3"
          expect(pacticipants.last.latest_version.number).to eq "12"
        end

        it "eager_loads" do
          pacticipants = Pacticipant.order(:id).eager(:latest_version).all
          expect(pacticipants.first.associations[:latest_version].number).to eq "3"
          expect(pacticipants.last.associations[:latest_version].number).to eq "12"
        end
      end
    end
  end
end
