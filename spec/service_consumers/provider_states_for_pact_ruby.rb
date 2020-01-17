require 'spec/support/test_data_builder'

Pact.provider_states_for "Pact Ruby" do

  provider_state "the relations for retrieving pacts exist in the index resource" do
    no_op
  end

  provider_state "the relation for retrieving pending pacts exists in the index resource" do
    no_op
  end

  provider_state "consumer-1 has a pending pact with provider provider-1" do
    set_up do
      TestDataBuilder.new
        .create_provider('provider-1')
        .create_consumer('consumer-1')
        .create_consumer_version('1.3.0')
        .create_pact
    end
  end

  provider_state 'consumer-1 and consumer-2 have pacts with provider provider-1' do
    set_up do
      TestDataBuilder.new
        .create_provider('provider-1')
        .create_consumer('consumer-1')
        .create_consumer_version('1.3.0')
        .create_pact
        .create_consumer('consumer-2')
        .create_consumer_version('1.4.0')
        .create_pact
    end
  end

  provider_state 'consumer-1 and consumer-2 have pacts with provider provider-1 tagged with tag-1' do
    set_up do
      TestDataBuilder.new
        .create_provider('provider-1')
        .create_consumer('consumer-1')
        .create_consumer_version('1.3.0')
        .create_consumer_version_tag('tag-1')
        .create_pact
        .create_consumer("consumer-2")
        .create_consumer_version('1.4.0')
        .create_consumer_version_tag('tag-1')
        .create_pact
    end
  end

  provider_state 'consumer-1 and consumer-2 have pacts with provider provider-1 tagged with tag-2' do
    set_up do
      TestDataBuilder.new
        .create_provider('provider-1')
        .create_consumer('consumer-1')
        .create_consumer_version('1.3.0')
        .create_consumer_version_tag('tag-2')
        .create_pact
        .create_consumer('consumer-2')
        .create_consumer_version('1.4.0')
        .create_consumer_version_tag('tag-2')
        .create_pact
    end
  end

  provider_state 'consumer-1 and consumer-2 have 2 pacts with provider provider-1 tagged with tag-1' do
    set_up do
      TestDataBuilder.new
        .create_provider('provider-1')
        .create_consumer('consumer-1')
        .create_consumer_version('1.3.0')
        .create_consumer_version_tag('tag-1')
        .create_pact
        .create_consumer('consumer-2')
        .create_consumer_version('1.4.0')
        .create_consumer_version_tag('tag-1')
        .create_pact
    end
  end

  provider_state 'consumer-1 and consumer-2 have 2 pacts with provider provider-1 tagged with tag-2' do
    set_up do
      TestDataBuilder.new
        .create_provider('provider-1')
        .create_consumer('consumer-1')
        .create_consumer_version('1.3.0')
        .create_consumer_version_tag('tag-2')
        .create_pact
        .create_consumer('consumer-2')
        .create_consumer_version('1.4.0')
        .create_consumer_version_tag('tag-2')
        .create_pact
    end
  end

  provider_state 'consumer-1 and consumer-2 have 2 pacts with provider provider-1' do
    set_up do
      TestDataBuilder.new
        .create_provider('provider-1')
        .create_consumer('consumer-1')
        .create_consumer_version('1.3.0')
        .create_pact
        .create_consumer('consumer-2')
        .create_consumer_version('1.4.0')
        .create_pact
    end
  end

  provider_state "consumer-1 and consumer-2 have no pacts with provider provider-1 tagged with tag-1" do
    set_up do
      TestDataBuilder.new
        .create_provider('provider-1')
        .create_consumer('consumer-1')
        .create_consumer_version('1.3.0')
        .create_pact
        .create_consumer('consumer-2')
        .create_consumer_version('1.4.0')
        .create_pact
    end
  end

  provider_state "consumer-1 and consumer-2 have pacts with provider provider-1 tagged with master" do
    set_up do
      TestDataBuilder.new
        .create_provider('provider-1')
        .create_consumer('consumer-1')
        .create_consumer_version('1.3.0')
        .create_consumer_version_tag('master')
        .create_pact
        .create_consumer('consumer-2')
        .create_consumer_version('1.4.0')
        .create_consumer_version_tag('master')
        .create_pact
    end
  end

  provider_state "consumer-1 has no pacts with provider provider-1 tagged with tag-1" do
    set_up do
      TestDataBuilder.new
        .create_provider('provider-1')
        .create_consumer('consumer-1')
        .create_consumer_version('1.3.0')
        .create_pact
    end
  end

  provider_state "the relation for retrieving pacts for verifications exists in the index resource" do
      no_op
    end

    provider_state "Foo has a pact tagged cdev with provider Bar" do
      set_up do
        TestDataBuilder.new
          .create_pact_with_hierarchy("Foo", "1", "Bar")
          .create_consumer_version_tag("cdev")
      end
    end
end
