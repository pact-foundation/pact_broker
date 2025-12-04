require "spec/support/test_data_builder"
require_relative "shared_provider_states"

Pact.provider_states_for "pact-broker-cli" do
  shared_provider_states
  shared_noop_provider_states




  provider_state "a pact between Condor and the Pricing Service exists with branch main" do
    set_up do
      TestDataBuilder.new
        .create_condor
        .create_consumer_version("1.3.0", branch: "main")
        .create_pricing_service
        .create_pact
    end
  end

  provider_state "a pact between Condor and the Pricing Service exists with branch feature" do
    set_up do
      TestDataBuilder.new
        .create_condor
        .create_consumer_version("1.3.0", branch: "feature")
        .create_pricing_service
        .create_pact
    end
  end

  provider_state "version 5556b8149bf8bac76bc30f50a8a2dd4c22c85f30 of pacticipant Foo exists with a test environment available for release" do
    set_up do
      TestDataBuilder.new
        .create_environment("test", uuid: "16926ef3-590f-4e3f-838e-719717aa88c9")
        .create_consumer("Foo")
        .create_consumer_version("5556b8149bf8bac76bc30f50a8a2dd4c22c85f30")
    end
  end

  provider_state "version 5556b8149bf8bac76bc30f50a8a2dd4c22c85f30 of pacticipant Foo exists with a test environment is released with id ff3adecf-cfc5-4653-a4e3-f1861092f8e0" do
    set_up do
      TestDataBuilder.new
        .create_environment("test", uuid: "16926ef3-590f-4e3f-838e-719717aa88c9")
        .create_consumer("Foo")
        .create_consumer_version("5556b8149bf8bac76bc30f50a8a2dd4c22c85f30")
        .create_released_version_for_consumer_version(uuid: "ff3adecf-cfc5-4653-a4e3-f1861092f8e0", environment_name: "test")
    end
  end

  provider_state "version 5556b8149bf8bac76bc30f50a8a2dd4c22c85f30 of pacticipant Foo exists with a test environment available for deployment" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Foo")
        .create_consumer_version("5556b8149bf8bac76bc30f50a8a2dd4c22c85f30")
        .create_environment("test", uuid: "16926ef3-590f-4e3f-838e-719717aa88c9")
    end
  end
end
