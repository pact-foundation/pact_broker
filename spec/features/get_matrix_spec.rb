require 'spec/support/test_data_builder'

describe "Get matrix" do
  before do
    TestDataBuilder.new
      .create_pact_with_hierarchy('Consumer', '1.0.0', 'Provider')
      .create_verification(provider_version: '4.5.6')
  end

  let(:path) { "/matrix/provider/Provider/consumer/Consumer" }
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get path; last_response }

  it "returns a 200 HAL JSON response" do
    expect(subject).to be_a_hal_json_success_response
  end

  it "returns the JSON representation of the matrix" do
    expect(last_response_body[:matrix][0][:consumer]).to be_instance_of(Hash)
    expect(last_response_body[:matrix][0][:provider]).to be_instance_of(Hash)
    expect(last_response_body[:matrix][0][:pact]).to be_instance_of(Hash)
    expect(last_response_body[:matrix][0][:verificationResult]).to be_instance_of(Hash)
  end
end
