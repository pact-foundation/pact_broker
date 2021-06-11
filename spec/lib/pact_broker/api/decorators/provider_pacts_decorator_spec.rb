require "pact_broker/api/decorators/provider_pacts_decorator"

module PactBroker
  module Api
    module Decorators
      describe ProviderPactsDecorator do

        let(:pacts) { [pact]}
        let(:pact) do
          double("pact", name: "Pact name", consumer_name: "Foo")
        end
        let(:user_options) do
          {
            base_url: "http://example.org",
            resource_url: "http://example.org/provider-pacts",
            title: "title",
            provider_name: "foo"
          }
        end

        before do
          allow_any_instance_of(ProviderPactsDecorator).to receive(:pact_url).and_return("pact_url")
        end

        subject { JSON.parse ProviderPactsDecorator.new(pacts).to_json(user_options: user_options), symbolize_names: true }

        let(:expected) do
          {
            :_links => {
              :self=> {
                :href=> "http://example.org/provider-pacts",
                :title => "title"
              },
              :"pb:provider" => {
                :href => "http://example.org/pacticipants/foo",
                :name => "foo"
              },
              :"pb:pacts" =>[{
                :href => "pact_url",
                :title => "Pact name",
                :name => "Foo" }],
              :pacts => [{
                :href => "pact_url",
                :title => "DEPRECATED - please use the pb:pacts relation. Pact name",
                :name => "Foo"
                }
              ]
            }
          }
        end

        it "matches the expected JSON" do
          expect(subject).to match_pact(expected)
        end
      end
    end
  end
end
