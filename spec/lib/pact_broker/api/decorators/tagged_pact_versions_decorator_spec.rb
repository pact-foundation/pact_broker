require 'pact_broker/api/decorators/tagged_pact_versions_decorator'

def register_fixture name
  yield
end


module PactBroker
  module Api
    module Decorators
      describe TaggedPactVersionsDecorator do

        let(:user_options) do
          register_fixture(:tagged_pact_versions_decorator_args) do
            {
              consumer_name: "Foo",
              provider_name: "Bar"
            }
          end
        end

        let(:pact_versions) { [pact_version] }
        let(:pact_version) do
          instance_double("PactBroker::Domain::Pact")
        end

        let(:decorator) { TaggedPactVersionsDecorator.new(pact_versions) }
        let(:json) { decorator.to_json(user_options: user_options) }
        subject { JSON.parse(json) }

        xit "" do
          subject(subject['_links']['pb:consumer']).to eq({})
        end

      end
    end
  end
end
