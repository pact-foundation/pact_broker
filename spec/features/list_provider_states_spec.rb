RSpec.describe "listing the provider states" do
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

  let(:path) { "/pacts/provider/Bar/provider-states" }

  subject { get(path, nil, rack_headers).tap { |it| puts it.body } }

  it { is_expected.to be_a_hal_json_success_response }

end