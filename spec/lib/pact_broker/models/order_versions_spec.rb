require 'spec_helper'
require 'spec/support/provider_state_builder'
require 'pact_broker/models/order_versions.rb'

describe PactBroker::Models::OrderVersions do


  before do
    ProviderStateBuilder.new
      .create_condor
      .create_condor_version('1.3.0')
      .create_condor_version('1.5.0')
      .create_condor_version('1.4.0')
  end

  let(:ordered_versions) { PactBroker::Models::Version.order(:order).all.collect(&:number) }
  let(:condor) { PactBroker::Models::Pacticipant.where(name: 'Condor').single_record }

  it "sorts the versions" do
    expect(ordered_versions).to eq(['1.3.0','1.4.0', '1.5.0'])
  end

end