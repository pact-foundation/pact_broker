require "spec/support/test_data_builder"

describe "Get matrix for consumer and provider" do
  before do
    td.create_pact_with_hierarchy("Consumer", "1.0.0", "Provider")
      .create_verification(provider_version: "4.5.6")
  end

  let(:path) { "/matrix" }
  let(:params) do
    {
      q: [
        { pacticipant: "Consumer", version: "1.0.0" },
        { pacticipant: "Provider", version: "4.5.6" }
      ]
    }
  end
  let(:rack_env) { {} }
  let(:last_response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get(path, params, rack_env) }

  it "returns a 200 HAL JSON response" do
    expect(subject).to be_a_hal_json_success_response
  end

  it "returns the JSON representation of the matrix" do
    expect(last_response_body[:matrix][0][:consumer]).to be_instance_of(Hash)
    expect(last_response_body[:matrix][0][:provider]).to be_instance_of(Hash)
    expect(last_response_body[:matrix][0][:pact]).to be_instance_of(Hash)
    expect(last_response_body[:matrix][0][:verificationResult]).to be_instance_of(Hash)
  end

  # A selector with both a version and an environment, combined with another selector, used to
  # cause a 500 (PG::UndefinedColumn: column "number" does not exist) when identifying the integrations
  # between the specified selectors.
  context "when a selector specifies both a version and an environment" do
    before do
      td.create_environment("production")
    end

    let(:params) do
      {
        q: [
          { pacticipant: "Consumer", version: "1.0.0" },
          { pacticipant: "Provider", version: "4.5.6", environment: "production" }
        ],
        latestby: "cvpv"
      }
    end

    context "when the version is currently deployed to the environment" do
      before do
        td.use_provider_version("4.5.6")
          .create_deployed_version_for_provider_version(environment_name: "production")
      end

      it "returns a 200 HAL JSON response" do
        expect(subject).to be_a_hal_json_success_response
      end

      it "returns the row for the versions" do
        expect(last_response_body[:matrix].size).to eq 1
        expect(last_response_body[:matrix][0][:provider][:version][:number]).to eq "4.5.6"
      end
    end

    context "when the version is currently released to the environment" do
      before do
        td.use_provider_version("4.5.6")
          .create_released_version_for_provider_version(environment_name: "production")
      end

      it "returns the row for the versions" do
        expect(subject).to be_a_hal_json_success_response
        expect(last_response_body[:matrix].size).to eq 1
      end
    end

    context "when the version is not in the environment" do
      it "returns a row for the integration with no provider version" do
        expect(subject).to be_a_hal_json_success_response
        expect(last_response_body[:matrix].size).to eq 1
        expect(last_response_body[:matrix][0][:consumer][:version][:number]).to eq "1.0.0"
        expect(last_response_body[:matrix][0][:provider][:version]).to be_nil
      end
    end
  end

  context "with Accept: text/plain" do
    let(:rack_env) { { "HTTP_ACCEPT" => "text/plain" } }

    its(:headers) { is_expected.to include("Content-Type" => "text/plain;charset=utf-8") }
  end
end
