describe "Get dashboard" do

  let(:path) { "/dashboard" }
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }
  let(:rack_env) { {} }
  before do
    td.create_consumer("Foo")
      .create_provider("Bar")
      .create_consumer_version("1.2.3")
      .create_consumer_version_tag("prod")
      .create_pact
      .create_verification(provider_version: "4.5.6", tag_names: "dev")
      .create_webhook
      .create_triggered_webhook
      .create_webhook_execution
  end

  subject { get(path, nil, rack_env) }

  it "returns a 200 HAL JSON response" do
    expect(subject).to be_a_hal_json_success_response
  end

  it "returns a list of items" do
    items = JSON.parse(subject.body)["items"]
    expect(items).to be_instance_of(Array)
  end

  context "with Accept: text/plain" do
    let(:rack_env) { { "HTTP_ACCEPT" => "text/plain" } }

    its(:headers) { is_expected.to include("Content-Type" => "text/plain;charset=utf-8") }
  end
end
