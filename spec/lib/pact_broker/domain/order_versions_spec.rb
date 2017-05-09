require 'spec_helper'
require 'spec/support/provider_state_builder'
require 'pact_broker/domain/order_versions.rb'

describe PactBroker::Domain::OrderVersions do

  context "when order_versions_by_date is false (the default)" do
    before do
      ProviderStateBuilder.new
        .create_condor
        .create_condor_version('1.3.0')
        .create_condor_version('1.5.0')
        .create_condor_version('1.4.0')
        .create_condor_version('1.6.0')
    end

    let(:ordered_versions) { PactBroker::Domain::Version.order(:order).all.collect(&:number) }
    let(:condor) { PactBroker::Domain::Pacticipant.where(name: 'Condor').single_record }

    it "orders the versions so they can be loaded from the database in order" do
      expect(ordered_versions).to eq(['1.3.0', '1.4.0', '1.5.0', '1.6.0'])
    end
  end

  context "when order_versions_by_date is true (not recommended)" do
    before do
      allow(PactBroker.configuration).to receive(:order_versions_by_date).and_return(true)
    end
    let(:consumer) { ProviderStateBuilder.new.create_consumer.and_return(:consumer) }
    let!(:version_1) { PactBroker::Domain::Version.create(pacticipant_id: consumer.id, number: '2', created_at: DateTime.new(2017)) }
    let!(:version_2) { PactBroker::Domain::Version.create(pacticipant_id: consumer.id, number: '1', created_at: DateTime.new(2017)) }
    let!(:version_3) { PactBroker::Domain::Version.create(pacticipant_id: consumer.id, number: '3', created_at: DateTime.new(2016)) }
    let!(:version_4) { PactBroker::Domain::Version.create(pacticipant_id: consumer.id, number: '4', created_at: DateTime.new(2018)) }

    let(:ordered_versions) { PactBroker::Domain::Version.order(:order).all.collect(&:number) }

    it "orders by date, then id" do
      expect(ordered_versions).to eq(['3', '2', '1', '4'])
    end

  end

end
