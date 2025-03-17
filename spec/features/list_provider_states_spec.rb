RSpec.describe "listing the provider states without params" do
  before do
    td.create_consumer("Foo", main_branch: "main")
      .publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "1", branch: "main", json_content: pact_content_1.to_json)
      .publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "2", branch: "not-main")
      .create_consumer("Waffle", main_branch: "main")
      .publish_pact(consumer_name: "Waffle", provider_name: "Bar", consumer_version_number: "1", branch: "main", json_content: pact_content_2.to_json)
  end

  let(:rack_headers) { { "HTTP_ACCEPT" => "application/hal+json" } }

  let(:pact_content_1) do
    {
      interactions: [
        {
          providerState: "state 2"
        },
        {
          providerState: "state 1"
        }
      ]
    }
  end

  let(:pact_content_2) do
    {
      interactions: [
        {
          providerStates: [ { name: "state 3" }, { name: "state 4" } ]
        },
        {
          providerStates: [ { name: "state 5" } ]
        }
      ]
    }
  end

  let(:expected_hash) do
    {
      "providerStates" => [
        { "consumers" => ["Foo"], "name" => "state 1" },
        { "consumers" => ["Foo"], "name" => "state 2" },
        { "consumers" => ["Waffle"], "name" => "state 3" },
        { "consumers" => ["Waffle"], "name" => "state 4" },
        { "consumers" => ["Waffle"], "name" => "state 5" }
      ]
    }
  end

  let(:response_body_hash) { JSON.parse(subject.body) }

  let(:path) { "/pacts/provider/Bar/provider-states" }

  subject { get(path, nil, rack_headers) }

  it { 
    is_expected.to be_a_hal_json_success_response
    expect(response_body_hash).to eq expected_hash
  }

end

RSpec.describe "listing the provider states with params" do
  before do
    td.create_consumer("Foo", main_branch: "main")
      .publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "1", branch: "main", json_content: pact_content_1.to_json)
      .publish_pact(consumer_name: "Foo2", provider_name: "Bar", consumer_version_number: "1", branch: "main", json_content: pact_content_1.to_json)
      .publish_pact(consumer_name: "Foo3", provider_name: "Bar", consumer_version_number: "1", branch: "main", json_content: pact_content_1.to_json)
      .publish_pact(consumer_name: "Foo4", provider_name: "Bar", consumer_version_number: "1", branch: "main", json_content: pact_content_1.to_json)
      .publish_pact(consumer_name: "Foo5", provider_name: "Bar", consumer_version_number: "1", branch: "main", json_content: pact_content_1.to_json)
      .publish_pact(consumer_name: "Foo6", provider_name: "Bar", consumer_version_number: "1", branch: "main", json_content: pact_content_3.to_json)
      .publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "2", branch: "not-main").create_consumer("Waffle", main_branch: "main")
      .publish_pact(consumer_name: "Waffle", provider_name: "Bar", consumer_version_number: "1", branch: "main", json_content: pact_content_2.to_json)
      .publish_pact(consumer_name: "Waffle2", provider_name: "Bar", consumer_version_number: "1", branch: "main", json_content: pact_content_2.to_json)
  end

  let(:rack_headers) { { "HTTP_ACCEPT" => "application/hal+json" } }

  let(:pact_content_1) do
    {
      interactions: [
        {
          providerStates: [ { name: "product details", params: { product_id: "058925f7-1763-4dd9-a057-50ee265e33a0" } } ]
        },
      ]
    }
  end

  let(:pact_content_2) do
    {
      interactions: [
        {
          providerStates: [ { name: "product list" } ]
        }
      ]
    }
  end

  let(:pact_content_3) do
    {
      interactions: [
        {
          providerStates: [ { name: "some other product list" } ]
        }
      ]
    }
  end

  let(:expected_hash) do
    {
      "providerStates" => [
        { "consumers" => ["Foo", "Foo2", "Foo3", "Foo4", "Foo5"], "name" => "product details", "params" => { "product_id" => "058925f7-1763-4dd9-a057-50ee265e33a0" } },
        { "consumers" => ["Waffle", "Waffle2"], "name" => "product list" },
        { "consumers" => ["Foo6"], "name" => "some other product list" }
      ]
    }
  end

  let(:response_body_hash) { JSON.parse(subject.body) }

  let(:path) { "/pacts/provider/Bar/provider-states" }

  subject { get(path, nil, rack_headers) }

  it { 
    is_expected.to be_a_hal_json_success_response
    expect(response_body_hash).to eq expected_hash
  }

end