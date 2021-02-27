Pact.provider_states_for "Pact Broker Client" do

  provider_state "the pb:pacticipant-version and pb:environments relations exist in the index resource" do
    no_op
  end

  provider_state "an environment with name test exists" do
    set_up do
      TestDataBuilder.new
        .create_environment("test")
    end
  end

  provider_state "version 5556b8149bf8bac76bc30f50a8a2dd4c22c85f30 of pacticipant Foo exists with a test environment available for deployment" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Foo")
        .create_consumer_version("5556b8149bf8bac76bc30f50a8a2dd4c22c85f30")
        .create_environment("test", uuid: "cb632df3-0a0d-4227-aac3-60114dd36479")
    end
  end

  provider_state "version 5556b8149bf8bac76bc30f50a8a2dd4c22c85f30 of pacticipant Foo does not exist" do
    no_op
  end

  provider_state "version 5556b8149bf8bac76bc30f50a8a2dd4c22c85f30 of pacticipant Foo exists with 2 environments that aren't test available for deployment" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Foo")
        .create_consumer_version("5556b8149bf8bac76bc30f50a8a2dd4c22c85f30")
        .create_environment("prod")
        .create_environment("dev")
    end
  end
end
