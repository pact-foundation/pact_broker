require "spec/support/test_data_builder"

Pact.provider_states_for "Pact Broker Client" do

  provider_state "the pb:latest-tagged-version relation exists in the index resource" do
    no_op
  end

  provider_state "'Condor' exists in the pact-broker with the latest tagged 'production' version 1.2.3" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Condor")
        .create_consumer_version("1.2.3")
        .create_consumer_version_tag("production")
        .create_consumer_version("2.0.0")
    end
  end

  provider_state "the pb:latest-version relation exists in the index resource" do
    no_op
  end

  provider_state "'Condor' exists in the pact-broker with the latest version 1.2.3" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Condor")
        .create_consumer_version("1.0.0")
        .create_consumer_version("1.2.3")
    end
  end

  provider_state "the 'Pricing Service' and 'Condor' already exist in the pact-broker" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Condor")
        .create_provider("Pricing Service")
    end
  end

  provider_state "the pact for Foo Thing version 1.2.3 has been verified by Bar version 4.5.6" do
    set_up do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo Thing", "1.2.3", "Bar")
        .revise_pact
        .create_verification(provider_version: "4.5.6")
        .create_verification(provider_version: "7.8.9", number: 2)
        .create_consumer_version("2.0.0")
        .create_pact
        .revise_pact
        .create_verification(provider_version: "4.5.6")
    end
  end

  provider_state "the pact for Foo version 1.2.3 has been verified by Bar version 4.5.6" do
    set_up do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
        .revise_pact
        .create_verification(provider_version: "4.5.6")
        .create_verification(provider_version: "7.8.9", number: 2)
        .create_consumer_version("2.0.0")
        .create_pact
        .revise_pact
        .create_verification(provider_version: "4.5.6")
    end
  end

  provider_state "the pact for Foo version 1.2.3 and 1.2.4 has been verified by Bar version 4.5.6" do
    set_up do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
        .revise_pact
        .create_verification(provider_version: "4.5.6")
        .create_consumer_version("1.2.4")
        .create_pact
        .revise_pact
        .create_verification(provider_version: "4.5.6")
    end
  end

  provider_state "the pact for Foo version 1.2.3 has been successfully verified by Bar version 4.5.6, and 1.2.4 unsuccessfully by 9.9.9" do
    set_up do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
        .revise_pact
        .create_verification(provider_version: "4.5.6")
        .create_consumer_version("1.2.4")
        .create_pact
        .revise_pact
        .create_verification(provider_version: "9.9.9", success: false)
    end
  end

  provider_state "the pact for Foo version 1.2.3 has been successfully verified by Bar version 4.5.6 with tag prod, and 1.2.4 unsuccessfully by 9.9.9" do
    set_up do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
        .revise_pact
        .create_verification(provider_version: "4.5.6")
        .use_provider("Bar")
        .use_provider_version("4.5.6")
        .create_provider_version_tag("prod")
        .create_consumer_version("1.2.4")
        .create_pact
        .revise_pact
        .create_verification(provider_version: "9.9.9", success: false)
    end
  end

  provider_state "the pact for Foo version 1.2.3 has been verified by Bar version 4.5.6 and version 5.6.7" do
    set_up do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
        .revise_pact
        .create_verification(provider_version: "4.5.6")
        .create_verification(provider_version: "5.6.7", number: 2)
    end
  end

  provider_state "the pact for Foo version 1.2.3 has been successfully verified by Bar version 4.5.6 (tagged prod) and version 5.6.7" do
    set_up do
      TestDataBuilder.new
        .create_pact_with_hierarchy("Foo", "1.2.3", "Bar")
        .create_verification(provider_version: "4.5.6")
        .use_provider_version("4.5.6")
        .create_provider_version_tag("prod")
        .create_verification(provider_version: "5.6.7", number: 2)
    end
  end

  provider_state "the 'Pricing Service' does not exist in the pact-broker" do
    no_op
  end

  provider_state "the 'Pricing Service' already exists in the pact-broker" do
    set_up do
      TestDataBuilder.new.create_pricing_service.create_provider_version("1.3.0")
    end
  end

  provider_state "an error occurs while publishing a pact" do
    set_up do
      require "pact_broker/pacts/service"
      allow(PactBroker::Pacts::Service).to receive(:create_or_update_pact).and_raise("an error")
    end
  end

  provider_state "a pact between Condor and the Pricing Service exists" do
    set_up do
      TestDataBuilder.new
        .create_condor
        .create_consumer_version("1.3.0")
        .create_pricing_service
        .create_pact
    end
  end

  provider_state "no pact between Condor and the Pricing Service exists" do
    no_op
  end

  provider_state "the 'Pricing Service' and 'Condor' already exist in the pact-broker, and Condor already has a pact published for version 1.3.0" do
    set_up do
      TestDataBuilder.new
        .create_condor
        .create_consumer_version("1.3.0")
        .create_pricing_service
        .create_pact
    end
  end

  provider_state "'Condor' already exist in the pact-broker, but the 'Pricing Service' does not" do
    set_up do
      TestDataBuilder.new.create_condor
    end
  end

  provider_state "'Condor' exists in the pact-broker" do
    set_up do
      TestDataBuilder.new.create_condor.create_consumer_version("1.3.0")
    end
  end

  provider_state "'Condor' exists in the pact-broker with version 1.3.0, tagged with 'prod'" do
    set_up do
      TestDataBuilder.new
        .create_pacticipant("Condor")
        .create_version("1.3.0")
        .create_tag("prod")
    end
  end

  provider_state "'Condor' does not exist in the pact-broker" do
    no_op
  end

   provider_state "a pact between Condor and the Pricing Service exists for the production version of Condor" do
     set_up do
       TestDataBuilder.new
         .create_consumer("Condor")
        .create_consumer_version("1.3.0")
        .create_consumer_version_tag("prod")
         .create_provider("Pricing Service")
         .create_pact
     end
   end

   provider_state "a pacticipant version with production details exists for the Pricing Service" do
     set_up do
       # Your set up code goes here
     end
   end

   provider_state "no pacticipant version exists for the Pricing Service" do
     no_op
   end

  provider_state "a latest pact between Condor and the Pricing Service exists" do
    set_up do
      TestDataBuilder.new
          .create_consumer("Condor")
          .create_consumer_version("1.3.0")
          .create_provider("Pricing Service")
          .create_pact
    end
  end

  provider_state "tagged as prod pact between Condor and the Pricing Service exists" do
    set_up do
      TestDataBuilder.new
          .create_consumer("Condor")
          .create_consumer_version("1.3.0")
          .create_consumer_version_tag("prod")
          .create_provider("Pricing Service")
          .create_pact
    end
  end

  provider_state "a webhook with the uuid 696c5f93-1b7f-44bc-8d03-59440fcaa9a0 exists" do
    set_up do
      TestDataBuilder.new
          .create_consumer("Condor")
          .create_provider("Pricing Service")
          .create_webhook(uuid: "696c5f93-1b7f-44bc-8d03-59440fcaa9a0")
    end
  end

  provider_state "the pacticipant relations are present" do
    no_op
  end

  provider_state "a pacticipant with name Foo exists" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Foo")
    end
  end

  provider_state "the pb:pacticipant-version relation exists in the index resource" do
    no_op
  end

  provider_state "version 26f353580936ad3b9baddb17b00e84f33c69e7cb of pacticipant Foo does not exist" do
    no_op
  end

  provider_state "version 26f353580936ad3b9baddb17b00e84f33c69e7cb of pacticipant Foo does exist" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Foo")
        .create_consumer_version("26f353580936ad3b9baddb17b00e84f33c69e7cb")
    end
  end

  provider_state "the pb:publish-contracts relations exists in the index resource" do
    no_op
  end

  provider_state "the pb:environments relation exists in the index resource" do
    no_op
  end

  provider_state "provider Bar version 4.5.6 has a successful verification for Foo version 1.2.3 tagged prod and a failed verification for version 3.4.5 tagged prod" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Foo")
        .create_provider("Bar")
        .create_consumer_version("1.2.3")
        .create_consumer_version_tag("prod")
        .create_pact
        .create_verification(provider_version: "4.5.6")
        .create_consumer_version("3.4.5")
        .create_consumer_version_tag("prod")
        .create_pact(json_content: TestDataBuilder.new.random_json_content("Foo", "Bar"))
        .create_verification(provider_version: "4.5.6", success: false)
    end
  end

  provider_state "an environment exists" do
    set_up do
      TestDataBuilder.new
        .create_environment("test", contacts: [ { name: "foo", details: { emailAddress: "foo@bar.com" } }])
    end
  end

  provider_state "version 5556b8149bf8bac76bc30f50a8a2dd4c22c85f30 of pacticipant Foo exists with a test environment available for release" do
    set_up do
      TestDataBuilder.new
        .create_environment("test", uuid: "cb632df3-0a0d-4227-aac3-60114dd36479")
        .create_consumer("Foo")
        .create_consumer_version("5556b8149bf8bac76bc30f50a8a2dd4c22c85f30")
    end
  end

  provider_state "an environment with name test and UUID 16926ef3-590f-4e3f-838e-719717aa88c9 exists" do
    set_up do
      TestDataBuilder.new
        .create_environment("test", uuid: "16926ef3-590f-4e3f-838e-719717aa88c9")
    end
  end

  provider_state "an version is deployed to environment with UUID 16926ef3-590f-4e3f-838e-719717aa88c9 with target customer-1" do
    set_up do
      TestDataBuilder.new
        .create_environment("test", uuid: "16926ef3-590f-4e3f-838e-719717aa88c9")
        .create_consumer("Foo")
        .create_consumer_version("5556b8149bf8bac76bc30f50a8a2dd4c22c85f30")
        .create_deployed_version_for_consumer_version(uuid: "ff3adecf-cfc5-4653-a4e3-f1861092f8e0", target: "customer-1")
    end
  end

  provider_state "a currently deployed version exists" do
    set_up do
      TestDataBuilder.new
        .create_environment("test", uuid: "cb632df3-0a0d-4227-aac3-60114dd36479")
        .create_consumer("Foo")
        .create_consumer_version("5556b8149bf8bac76bc30f50a8a2dd4c22c85f30")
        .create_deployed_version_for_consumer_version(uuid: "ff3adecf-cfc5-4653-a4e3-f1861092f8e0")
    end
  end

  provider_state "the pb:pacticipant-branch relation exists in the index resource" do
    no_op
  end

  provider_state "a branch named main exists for pacticipant Foo" do
    set_up do
      TestDataBuilder.new
        .create_consumer("Foo")
        .create_consumer_version("1", branch: "main")
    end
  end
end
