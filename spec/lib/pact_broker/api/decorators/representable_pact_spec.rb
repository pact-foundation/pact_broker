require 'spec_helper'
require 'spec/support/test_data_builder'
require 'pact_broker/api/decorators/representable_pact'

module PactBroker::Api::Decorators
  describe RepresentablePact do
    let(:pact) { TestDataBuilder.new.create_pact_with_hierarchy('Consumer', '1.2.3', 'Provider').and_return(:pact) }

    subject { RepresentablePact.new(pact) }

    describe "initialize" do
      it "creates an object with a provider with a name" do
        expect(subject.provider.name).to eq 'Provider'
      end

      it "creates an object with a provider with a nil version" do
        expect(subject.provider.version).to be_nil
      end

      it "creates an object with a consumer with a name" do
        expect(subject.consumer.name).to eq 'Consumer'
      end

      it "creates an object with a consumer that has the current pact's version" do
        expect(subject.consumer.version.number).to eq '1.2.3'
      end
    end
  end
end