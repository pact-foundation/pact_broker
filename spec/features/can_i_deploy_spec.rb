RSpec.describe "can i deploy" do
  before do
    td.publish_pact(consumer_name: "Foo", provider_name: "Bar", consumer_version_number: "1.2.3", tags: ["dev"], branch: "main")
      .create_environment("prod")
  end

  let(:query) do
    {
      pacticipant: "Foo",
      version: "1.2.3",
      to: "prod"
    }
  end

  let(:response_body) { JSON.parse(subject.body, symbolize_names: true) }

  subject { get("/can-i-deploy", query, { "HTTP_ACCEPT" => "application/hal+json"}) }

  it "returns the matrix response" do
    expect(subject).to be_a_hal_json_success_response
    expect(response_body[:matrix]).to be_instance_of(Array)
  end

  context "using the URL format for tags" do
    subject { get("/pacticipants/Foo/latest-version/dev/can-i-deploy/to/prod", nil, { "HTTP_ACCEPT" => "application/hal+json"}) }

    it "returns the matrix response" do
      expect(subject).to be_a_hal_json_success_response
      expect(response_body[:matrix]).to be_instance_of(Array)
    end

    context "the badge" do
      subject { get("/pacticipants/Foo/latest-version/dev/can-i-deploy/to/prod/badge") }

      it "returns a redirect URL" do
        expect(subject.status).to eq 307
        expect(subject.headers["Location"]).to start_with("https://img.shields.io/badge/")
        expect(subject.headers["Location"]).to match(/dev/)
        expect(subject.headers["Location"]).to match(/prod/)
      end
    end
  end

  context "using the URL format for branch/environment" do
    subject { get("/pacticipants/Foo/branches/main/latest-version/can-i-deploy/to-environment/prod", nil, { "HTTP_ACCEPT" => "application/hal+json"}) }

    it "returns the matrix response" do
      expect(subject).to be_a_hal_json_success_response
      expect(response_body[:matrix]).to be_instance_of(Array)
    end

    context "the badge" do
      subject { get("/pacticipants/Foo/branches/main/latest-version/can-i-deploy/to-environment/prod/badge") }

      it "returns a redirect URL" do
        expect(subject.status).to eq 307
        expect(subject.headers["Location"]).to start_with("https://img.shields.io/badge/")
        expect(subject.headers["Location"]).to match(/main/)
        expect(subject.headers["Location"]).to match(/prod/)
      end
    end
  end

  context "with a validation error" do
    let(:query) { {} }

    it "returns an error response" do
      expect(subject.status).to eq 400
      expect(response_body[:errors]).to be_instance_of(Hash)
    end
  end

  # End-to-end guard for issue #903: when multiple versions of a provider are released to an
  # environment, can-i-deploy must evaluate every co-resident version, not just the latest.
  context "when multiple versions of the provider are released to an environment and an older one is incompatible" do
    before do
      td.create_environment("production")
        .create_pact_with_hierarchy("Waffle", "1", "Pancake")
        .create_verification(provider_version: "10", number: 1, success: false)
        .create_released_version_for_provider_version(environment_name: "production")
        .create_verification(provider_version: "11", number: 2, success: true)
        .create_released_version_for_provider_version(environment_name: "production")
    end

    let(:query) { { pacticipant: "Waffle", version: "1", environment: "production" } }

    it "returns a row for every released provider version and is not deployable" do
      expect(subject).to be_a_hal_json_success_response
      expect(response_body[:matrix].size).to eq 2
      expect(response_body[:summary][:deployable]).to be false
    end
  end

  context "when multiple versions of the provider are released to an environment and all are compatible" do
    before do
      td.create_environment("production")
        .create_pact_with_hierarchy("Waffle", "1", "Pancake")
        .create_verification(provider_version: "10", number: 1, success: true)
        .create_released_version_for_provider_version(environment_name: "production")
        .create_verification(provider_version: "11", number: 2, success: true)
        .create_released_version_for_provider_version(environment_name: "production")
    end

    let(:query) { { pacticipant: "Waffle", version: "1", environment: "production" } }

    it "returns a row for every released provider version and is deployable" do
      expect(subject).to be_a_hal_json_success_response
      expect(response_body[:matrix].size).to eq 2
      expect(response_body[:summary][:deployable]).to be true
    end
  end

  context "when multiple versions of the provider are deployed to an environment on different application instances and all are compatible" do
    before do
      td.create_environment("production")
        .create_pact_with_hierarchy("Waffle", "1", "Pancake")
        .create_verification(provider_version: "10", number: 1, success: true)
        .create_deployed_version_for_provider_version(environment_name: "production", target: "instance-1")
        .create_verification(provider_version: "11", number: 2, success: true)
        .create_deployed_version_for_provider_version(environment_name: "production", target: "instance-2")
    end

    let(:query) { { pacticipant: "Waffle", version: "1", environment: "production" } }

    it "returns a row for every deployed provider version and is deployable" do
      expect(subject).to be_a_hal_json_success_response
      expect(response_body[:matrix].size).to eq 2
      expect(response_body[:summary][:deployable]).to be true
    end
  end

  context "when multiple versions of the provider are deployed to an environment on different application instances and one is incompatible" do
    before do
      td.create_environment("production")
        .create_pact_with_hierarchy("Waffle", "1", "Pancake")
        .create_verification(provider_version: "10", number: 1, success: false)
        .create_deployed_version_for_provider_version(environment_name: "production", target: "instance-1")
        .create_verification(provider_version: "11", number: 2, success: true)
        .create_deployed_version_for_provider_version(environment_name: "production", target: "instance-2")
    end

    let(:query) { { pacticipant: "Waffle", version: "1", environment: "production" } }

    it "returns a row for every deployed provider version and is not deployable" do
      expect(subject).to be_a_hal_json_success_response
      expect(response_body[:matrix].size).to eq 2
      expect(response_body[:summary][:deployable]).to be false
    end
  end

  context "when a single version of the provider is deployed to an environment without an application instance and is incompatible" do
    before do
      td.create_environment("production")
        .create_pact_with_hierarchy("Waffle", "1", "Pancake")
        .create_verification(provider_version: "10", number: 1, success: false)
        .create_deployed_version_for_provider_version(environment_name: "production")
    end

    let(:query) { { pacticipant: "Waffle", version: "1", environment: "production" } }

    it "is not deployable" do
      expect(subject).to be_a_hal_json_success_response
      expect(response_body[:matrix].size).to eq 1
      expect(response_body[:summary][:deployable]).to be false
    end
  end

  context "when multiple versions of the provider are deployed to an environment and last is incompatible" do
    before do
      td.create_environment("production")
        .create_pact_with_hierarchy("Waffle", "1", "Pancake")
        .create_verification(provider_version: "10", number: 1, success: true)
        .create_deployed_version_for_provider_version(environment_name: "production")
        .create_verification(provider_version: "11", number: 2, success: false)
        .create_deployed_version_for_provider_version(environment_name: "production")
    end

    let(:query) { { pacticipant: "Waffle", version: "1", environment: "production" } }

    it "only considers the currently deployed version (the redeployment replaced the previous one) and is not deployable" do
      expect(subject).to be_a_hal_json_success_response
      expect(response_body[:matrix].size).to eq 1
      expect(response_body[:summary][:deployable]).to be false
    end
  end

  context "when multiple versions of the provider are deployed to an environment and last is compatible" do
    before do
      td.create_environment("production")
        .create_pact_with_hierarchy("Waffle", "1", "Pancake")
        .create_verification(provider_version: "10", number: 1, success: false)
        .create_deployed_version_for_provider_version(environment_name: "production")
        .create_verification(provider_version: "11", number: 2, success: true)
        .create_deployed_version_for_provider_version(environment_name: "production")
    end

    let(:query) { { pacticipant: "Waffle", version: "1", environment: "production" } }

    it "only considers the currently deployed version (the redeployment replaced the previous one) and is deployable" do
      expect(subject).to be_a_hal_json_success_response
      expect(response_body[:matrix].size).to eq 1
      expect(response_body[:summary][:deployable]).to be true
    end
  end
end
