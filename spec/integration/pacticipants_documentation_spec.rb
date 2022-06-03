require "timecop"
require "tzinfo"

PACTICIPANT_TESTED_DOCUMENTATION_PATHS = []
PACTICIPANTS_NO_DOCUMENTATION = %w[
]
PACTICIPANT_ROUTES_REQURING_A_DOCUMENTATION_TEST = PactBroker.routes
      .select { | route | route.path_include?("pacticipant") }
      .reject { | route | PACTICIPANTS_NO_DOCUMENTATION.include?(route.path) }

# Fails on Github Actions
RSpec.describe "pacticipant routes" do
  before do
    Timecop.freeze(Time.new(2021, 9, 1, 10, 7, 21, TZInfo::Timezone.get("Australia/Melbourne")))
    allow(PactBroker.configuration).to receive(:user_agent).and_return("Pact Broker")
    allow(PactBroker.configuration).to receive(:base_urls).and_return(["http://pact-broker"])
    td.create_consumer("foo")
      .create_provider("bar")
      .create_consumer_version("3e1f00a04")
      .create_pact(json_content: { integrations: [] }.to_json )
      .create_verification(provider_version: "950e7a154")
  end

  after do
    Timecop.return
  end

  before do
    if ENV["DEBUG"] == "true"
      PactBroker.routes.find{ | route| route.path == path_template }
    end
    PACTICIPANT_TESTED_DOCUMENTATION_PATHS << path_template
  end

  after(:all) do
    missed_routes = PACTICIPANT_ROUTES_REQURING_A_DOCUMENTATION_TEST.reject { | route | PACTICIPANT_TESTED_DOCUMENTATION_PATHS.include?(route.path) }

    if missed_routes.any? && ENV["DEBUG"] != "true"
      #puts "PACTICIPANT ROUTES MISSING DOCUMENTATION COVERAGE:"
      #puts missed_routes.to_yaml
    end
  end

  let(:category) { "Pacticipants" }
  let(:pact_version_sha) { PactBroker::Pacts::PactVersion.last.sha }


  let(:parameter_values) do
    {
      pacticipant_name: "foo",
      consumer_name: "foo",
      provider_name: "bar",
      consumer_version_number: "2",
      provider_version_number: "3"
    }
  end

  let(:custom_parameter_values) do
    {

    }
  end

  let(:rack_headers) do
    {
      "ACCEPT" => "application/hal+json",
      "pactbroker.base_url" => "https://pact-broker"
    }
  end

  let(:http_params) { {} }
  let(:http_method) { "GET" }

  let(:path) do
    build_path(path_template, parameter_values, custom_parameter_values)
  end

  let(:comments) { nil }

  let(:approval_request_example_name) do
    build_approval_name(category, pact_broker_example_name, http_method)
  end

  let(:pact_broker_example_name) do | example |
    example.example_group.parent_groups[-2].description
  end

  subject { send(http_method.downcase, path, http_params, rack_headers) }

  let(:fixture) { expected_interaction(subject, PACTICIPANT_TESTED_DOCUMENTATION_PATHS.size, comments) }

  def remove_deprecated_keys(interaction)
    if interaction.dig(:response, :body).is_a?(Hash)
      interaction.dig(:response, :body, "_embedded")&.delete("latest-version")
    end
    interaction
  end

  shared_examples "request" do
    it "returns a body" do
      subject
      Approvals.verify(fixture, :name => approval_request_example_name, format: :json)
    end
  end

  shared_examples "supports GET" do
    its(:status) { is_expected.to eq 200 }
    include_examples "request"
  end


  shared_examples "supports POST" do
    let(:http_method) { "POST" }
    let(:rack_headers) do
      {
        "CONTENT_TYPE" => "application/json",
        "ACCEPT" => "application/hal+json",
        "pactbroker.base_url" => "https://pact-broker"
      }
    end

    its(:status) { is_expected.to be_between(200, 201) }
    include_examples "request"

  end

  shared_examples "supports PUT" do
    describe "PUT" do
      let(:http_method) { "PUT" }
      let(:rack_headers) do
        {
          "CONTENT_TYPE" => "application/json",
          "ACCEPT" => "application/hal+json",
          "pactbroker.base_url" => "https://pact-broker"
        }
      end

      its(:status) { is_expected.to be_between(200, 201) }

      include_examples "request"
    end
  end

  shared_examples "supports OPTIONS" do
    let(:http_method) { "OPTIONS" }

    its(:status) { is_expected.to eq 200 }
    include_examples "request"
  end


  describe "Pacticipant" do
    let(:fixture) { remove_deprecated_keys(expected_interaction(subject, PACTICIPANT_TESTED_DOCUMENTATION_PATHS.size, comments)) }

    let(:path_template) { "/pacticipants/:pacticipant_name" }

    let(:pacticipant_hash) do
      {
        displayName: "Foo",
        repositoryUrl: "https://github.com/example/foo",
        repositoryName: "foo",
        repositoryNamespace: "example",
        mainBranch: "main"
      }
    end

    describe "GET" do
      include_examples "supports GET"
    end

    describe "PUT" do
      let(:comments) { "PUT replaces the entire resource with the specified body, so missing properties will effectively be nulled. Embedded properties (eg. versions) will not be affected." }

      let(:http_params) { pacticipant_hash.to_json }
      include_examples "supports PUT"
    end

    describe "PATCH" do
      let(:comments) { "PATCH with the Content-Type application/merge-patch+json merges the pacticipant's existing properties with those from the request body. Embedded properties (eg. versions) will not be affected." }
      let(:http_method) { "PATCH" }
      let(:rack_headers) do
        {
          "CONTENT_TYPE" => "application/merge-patch+json",
          "ACCEPT" => "application/hal+json",
          "pactbroker.base_url" => "https://pact-broker"
        }
      end
      let(:http_params) { pacticipant_hash.to_json }

      its(:status) { is_expected.to be_between(200, 201) }

      include_examples "request"
    end


    # TODO PATCH

    describe "OPTIONS" do
      include_examples "supports OPTIONS"
    end
  end
end
