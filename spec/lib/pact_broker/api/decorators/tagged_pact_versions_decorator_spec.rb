require "pact_broker/api/decorators/tagged_pact_versions_decorator"

module PactBroker
  module Api
    module Decorators
      describe TaggedPactVersionsDecorator do
        before do
          allow(PactBroker::Api::Decorators::PactVersionDecorator).to receive(:new).and_return(_version_decorator)
          allow_any_instance_of(TaggedPactVersionsDecorator).to receive(:pact_url).and_return("pact_url")
          allow_any_instance_of(TaggedPactVersionsDecorator).to receive(:pacticipant_url).and_return("pacticipant_url")
          allow_any_instance_of(TaggedPactVersionsDecorator).to receive(:pacticipant_url).and_return("pacticipant_url")
        end

        let(:user_options) do
          register_fixture(:tagged_pact_versions_decorator_user_options) do
            {
              base_url: "http://example.org",
              resource_url: "http://example.org/pacts/provider/Bar/consumer/Foo/tag/prod",
              consumer_name: "Foo",
              provider_name: "Bar",
              tag: "prod"
            }
          end
        end

        let(:_version_decorator) do
          instance_double(PactBroker::Api::Decorators::VersionDecorator, to_hash: { some: "pact" } )
        end
        let(:pact_versions) { [pact_version] }
        let(:pact_version) do
          instance_double("PactBroker::Domain::Pact").as_null_object
        end

        let(:decorator) { TaggedPactVersionsDecorator.new(pact_versions) }
        let(:json) { decorator.to_json(user_options: user_options) }
        subject { JSON.parse(json) }

        let(:expected) do
          {
           "_embedded" => {
             "pacts" => [
               {
                 "some" => "pact"
               }
             ]
           },
           "_links" => {
             "self" => {
               "href" => "http://example.org/pacts/provider/Bar/consumer/Foo/tag/prod",
               "title" => "All versions of the pact between Foo and Bar with tag prod"
             },
             "pb:consumer" => {
               "href" => "pacticipant_url",
               "title" => "Consumer",
               "name" => "Foo"
             },
             "pb:provider" => {
               "href" => "pacticipant_url",
               "title" => "Provider",
               "name" => "Bar"
             },
             "pb:pact-versions" => [
               {
                 "href" => "pact_url",
                 "title" => "Pact version",
                 "name" => "#[InstanceDouble(PactBroker::Domain::Pact) (anonymous)]"
               }
             ]
           }
          }
        end

        it "matches the expected JSON" do
          expect(subject).to match_pact(expected, allow_unexpected_keys: false)
        end
      end
    end
  end
end
