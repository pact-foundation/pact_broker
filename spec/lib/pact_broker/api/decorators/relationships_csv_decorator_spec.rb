require 'spec_helper'
require 'pact_broker/api/decorators/relationships_csv_decorator'

module PactBroker

  module Api

    module Decorators

      describe RelationshipsCsvDecorator do

        let(:pact) { ProviderStateBuilder.new.create_pact_with_hierarchy "My Consumer", "1.0", "My Provider"}
        let(:pacts) { [pact]}
        let(:line_1) { 'source,target,value'}
        let(:line_2) { 'My Consumer,My Provider,1' }
        let(:expected_text) { [line_1, line_2].join("\n") + "\n" }

        subject { RelationshipsCsvDecorator.new(pacts) }


        describe "#to_csv" do
          it "returns the relationships as CSV" do
            expect(subject.to_csv).to eq expected_text
          end
        end

      end
    end
  end
end