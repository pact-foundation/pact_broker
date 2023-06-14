require "pact_broker/api/decorators/webhooks_decorator"

module PactBroker
  module Api
    module Decorators
      describe WebhooksDecorator do

        let(:webhook) do
          instance_double(Domain::Webhook,
            uuid: "some-uuid",
            display_description: "description",
            scope_description: "scope description"
          )
        end
        let(:base_url) { "http://example.org" }
        let(:resource_url) { "http://example.org/webhooks" }

        let(:decorator_context) do
          DecoratorContext.new(base_url, resource_url, {}, resource_title: "Title")
        end

        let(:webhooks) { [webhook] }

        describe "to_json" do

          let(:json) { WebhooksDecorator.new(webhooks).to_json(user_options: decorator_context) }

          subject { JSON.parse(json, symbolize_names: true) }

          it "includes a link to itself with a title" do
            expect(subject[:_links][:self][:href]).to eq resource_url
            expect(subject[:_links][:self][:title]).to eq "Title"
          end

          it "includes a list of links to the webhooks" do
            expect(subject[:_links][:'pb:webhooks']).to be_instance_of(Array)
            expect(subject[:_links][:'pb:webhooks'].first).to eq title: "scope description", name: "description", href: "http://example.org/webhooks/some-uuid"
          end

          it "includes curies" do
            expect(subject[:_links][:curies]).to eq [{:name=>"pb", :href=>"http://example.org/doc/webhooks-{rel}", templated: true}]
          end
        end
      end
    end
  end
end
