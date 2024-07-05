Pact.provider_states_for "JVM Pact Broker Client" do

  provider_state "A pact has been published between the Provider and Foo Consumer" do
    set_up do
    	TestDataBuilder.new
    		.create_pact_with_hierarchy("Foo Consumer", "1", "Provider")
    	PactBroker::Pacts::PactVersion.first.update(sha: "1234567890")
    end
  end

  provider_state "No pact has been published between the Provider and Foo Consumer and there is a similar consumer" do
    set_up do
      # Your set up code goes here
    end
  end

  provider_state "No pact has been published between the Provider and Foo Consumer" do
    set_up do
      # Your set up code goes here
    end
  end

  provider_state "Two consumer pacts exist for the provider" do
    set_up do
      TestDataBuilder.new
        .create_provider("Activity Service")
        .create_consumer("Foo Web Client")
        .create_consumer_version("0.0.0-TEST")
        .create_pact
        .create_consumer("Foo Web Client 2")
        .create_consumer_version("0.0.0-TEST")
        .create_pact

    end
  end

  provider_state "pact for consumer2 is pending" do
    set_up do
      # Your set up code goes here
    end
  end

  provider_state "pact for consumer2 is wip" do
    set_up do
      # Your set up code goes here
    end
  end

  provider_state "the pact for Foo version 1.2.3 has been successfully verified by Bar version 4.5.6 (tagged prod) and version 5.6.7" do
    set_up do
      TestDataBuilder.new
      	.create_consumer("Foo")
      	.create_provider("Bar")
      	.create_consumer_version("1.2.3")
      	.create_pact
      	.create_verification(provider_version: "4.5.6", tag_names: ["prod"])
      	.create_verification(provider_version: "5.6.7", number: 2)
    end
  end

  provider_state "the pact for Foo version 1.2.3 has been verified by Bar version 4.5.6 and version 5.6.7" do
    set_up do
      TestDataBuilder.new
    		.create_pact_with_verification("Foo", "1.2.3", "Provider", "5.6.7")
    end
  end

end