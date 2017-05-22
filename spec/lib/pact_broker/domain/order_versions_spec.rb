require 'spec_helper'
require 'spec/support/provider_state_builder'
require 'pact_broker/domain/order_versions.rb'

describe PactBroker::Domain::OrderVersions do

  before do
    allow(PactBroker.configuration).to receive(:order_versions_by_date).and_return(false)
  end
  context "when order_versions_by_date is false (the default)" do
    before do
      ProviderStateBuilder.new
        .create_condor
        .create_condor_version('1.5.0')
        .create_condor_version('1.4.0')
        .create_condor_version('1.3.0')
        .create_condor_version('1.6.0')
    end

    let(:ordered_versions) { PactBroker::Domain::Version.order(:order).all.collect(&:number) }

    it "orders the versions semantically" do
      expect(ordered_versions).to eq(['1.3.0', '1.4.0', '1.5.0', '1.6.0'])
    end
  end

  context "when order_versions_by_date is true (not recommended)" do
    before do
      allow(PactBroker.configuration).to receive(:order_versions_by_date).and_return(true)
    end
    let(:consumer) { ProviderStateBuilder.new.create_consumer.and_return(:consumer) }
    let!(:version_1) { PactBroker::Domain::Version.create(pacticipant_id: consumer.id, number: '2') }
    let!(:version_2) { PactBroker::Domain::Version.create(pacticipant_id: consumer.id, number: '1') }
    let!(:version_3) { PactBroker::Domain::Version.create(pacticipant_id: consumer.id, number: '3') }
    let!(:version_4) { PactBroker::Domain::Version.create(pacticipant_id: consumer.id, number: '4') }

    let(:ordered_versions) { PactBroker::Domain::Version.order(:order).all.collect(&:number) }

    it "orders by insertion order" do
      expect(ordered_versions).to eq(['2', '1', '3', '4'])
    end

  end

  context "when an existing version number in the database that Versionomy could parse cannot be parsed by SemVer" do
    let!(:consumer) do
      ProviderStateBuilder.new
        .create_consumer
        .create_consumer_version('1')
        .create_consumer_version('2')
        .create_consumer_version('3')
        .create_consumer_version('4')
        .and_return(:consumer)
    end

    let(:ordered_versions) { PactBroker::Domain::Version.order(:order).all.collect(&:number) }

    context "when the new version is considered to be the latest" do
      before do
        Sequel::Model.db[:versions].where(number: '1').update(number: 'z')
        Sequel::Model.db[:versions].where(number: '2').update(number: 'a')
        Sequel::Model.db[:versions].where(number: '4').update(number: 'h')
      end

      it "just uses the next order number for the new version" do
        PactBroker::Domain::Version.create(number: '5', pacticipant_id: consumer.id)
        expect(ordered_versions).to eq(['z', 'a', '3', 'h', '5'])
      end
    end

    context "when the new version is considered to be earlier than the previous latest version" do

      before do
        Sequel::Model.db[:versions].where(number: '2').update(number: 'z')
        Sequel::Model.db[:versions].where(number: '3').update(number: 'a')
      end

      it "inserts the new version in the right place" do
        # 1 z a 4
        PactBroker::Domain::Version.create(number: '2', pacticipant_id: consumer.id)
        expect(ordered_versions).to eq(['1', 'z', 'a', '2', '4'])
      end

    end
  end

end
