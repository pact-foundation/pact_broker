require "pact_broker/api/decorators/labels_decorator"
require "pact_broker/labels/service"

module PactBroker
  module Api
    module Decorators

      describe LabelsDecorator do
        before do
          td.create_consumer("Foo")
            .create_label("consumer")
            .create_consumer("Bar")
            .create_label("provider")
            .create_consumer("Wiffle")
            .create_label("provider")
        end

        let(:label) do
          PactBroker::Labels::Service.get_all_unique_labels
        end

        let(:options) { { user_options: { resource_url: "http://example.org/labels", hide_label_decorator_links: true } } }
        subject { JSON.parse LabelsDecorator.new(label).to_json(options), symbolize_names: true }

        it "includes the label names" do
          expect(subject[:_embedded][:labels].map { |label| label[:name] }).to contain_exactly("provider", "consumer")
        end

        it "includes the resource url" do
          expect(subject[:_links][:self][:href]).to eq "http://example.org/labels"
        end

        it "labels field doest not include any links" do
          expect(subject[:_embedded][:labels][0][:_links]).to be_nil
        end

        it "doest not include createdAt" do
          expect(subject[:_embedded][:labels][0][:createdAt]).to be_nil
        end
      end
    end
  end
end
