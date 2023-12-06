# The purpose of this spec is to ensure that every new resource either has a policy_record, or it does not need a policy_record
# (because the all the context can be implied from the route, which will most likely contain a :pacticipant, or a :consumer, and/or a :provider).
# This test will fail when a new resource is added that does not either have a policy_record which returns an object,
# or has not been explicitly ignored in the spec/support/all_routes_spec_support.yml file.

require "pact_broker/api"
require "pact_broker/pacts/generate_sha"

PACT_CONTENT = TestDataBuilder.new.fixed_json_content("foo", "bar", "1")
PACT_VERSION_SHA = PactBroker::Pacts::GenerateSha.call(PACT_CONTENT)

UUID = "343434"

POTENTIAL_PARAMS = {
  pacticipant_name: "foo",
  pacticipant_version_number: "1",
  consumer_name: "foo",
  consumer_version_number: "1",
  provider_name: "bar",
  tag: "prod",
  environment_uuid: "1234",
  pact_version_sha: PACT_VERSION_SHA,
  to: "prod",
  verification_number: "1",
  comparison_pact_version_sha: "6789",
  tag_name: "prod",
  branch_name: "main",
  version_number: "1",
  uuid: UUID
}

REQUESTS_WHICH_ARE_EXECTED_TO_HAVE_NO_POLICY_RECORD = YAML.safe_load(File.read("spec/support/all_routes_spec_support.yml"))["requests_which_are_exected_to_have_no_policy_record_or_pacticipant"]

# Ensure that every resource/http method has a way of determining whether or not a user is allowed to call it.
# The actual permissions logic will be performed in Pactflow as the Pact Broker does not support a permissions model.
# Almost every route should either be associated with a pacticipant, or it should have a method to provide the policy_record.
# Some routes, as listed in spec/support/all_routes_spec_support.yml do not need either.
# This test is here to ensure that every new route added to the Pact Broker API has been considered, and explictly whitelisted if necessary.
PactBroker.routes.each do | pact_broker_route |
  describe "#{pact_broker_route.path} (#{pact_broker_route.resource_name})" do
    (pact_broker_route.allowed_methods - ["OPTIONS"]).each do | allowed_method |

      if !REQUESTS_WHICH_ARE_EXECTED_TO_HAVE_NO_POLICY_RECORD.include?("#{pact_broker_route.resource_name} #{allowed_method}")

        describe allowed_method do
          before do
            # Create test data that matches the POTENTIAL_PARAMS above so that every route has data present for it
            td.create_consumer("foo")
              .create_provider("bar")
              .create_consumer_version("1", branch: "main", tag_names: ["prod"])
              .create_pact(json_content: PACT_CONTENT)
              .create_verification(provider_version: "2", branch: "main", tag_names: ["prod"])
              .create_environment("prod", uuid: "1234")
              .create_deployed_version_for_consumer_version(uuid: "343434")
              .create_released_version_for_provider_version(uuid: "343434")
              .create_consumer_webhook(uuid: UUID)
              .create_triggered_webhook(uuid: UUID)
            PactBroker::Pacts::PactVersion.first.update(sha: PACT_VERSION_SHA)
          end

          it "has a policy record object or a consumer/provider/pacticipant in the route" do
            resource = pact_broker_route.build_resource({ "REQUEST_METHOD" => allowed_method }, PactBroker::ApplicationContext.default_application_context, POTENTIAL_PARAMS)

            thing = resource.consumer || resource.provider || resource.pacticipant || resource.respond_to?(:policy_record)

            expect(thing).to_not be_falsy
          end
        end
      end
    end
  end
end

RSpec.describe "all the routes" do
  it "has a name for every route" do
    expect(PactBroker.routes.reject(&:resource_name)).to eq []
  end

  it "has a unique name (except for the ones that don't which we can't change now because it would ruin the PF metrics)" do
    duplicates =  PactBroker.routes.collect(&:resource_name).group_by(&:itself).select { | _, values | values.size > 1 }.keys
    expect(duplicates).to eq(["pact_publication", "verification_results", "verification_result"])
  end
end
