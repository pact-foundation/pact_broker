require 'spec/support/test_data_builder'

describe "Delete version" do

  let(:path) { "/pacticipants/Consumer/versions/1.2.3" }
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { delete path; last_response }

  before do
    TestDataBuilder.new
      .create_consumer("Another Consumer")
      .create_consumer("Consumer")
      .create_consumer_version("1.2.3")
      .create_consumer_version_tag("prod")
      .create_consumer_version("1.2.4")
  end

  it "returns a 200 HAL JSON response" do
    expect(subject.status).to eq 204
  end
end
