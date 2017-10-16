require 'spec_helper'
require 'pact_broker/api/decorators/relationships_csv_decorator'

module PactBroker

  module Api

    module Decorators

      describe RelationshipsCsvDecorator do

        let(:pact) { TestDataBuilder.new.create_pact_with_hierarchy("My Consumer", "1.0", "My Provider").and_return(:pact) }
        let(:pacts) { [pact]}


        subject { RelationshipsCsvDecorator.new(pacts) }


        describe "#to_csv" do

          let(:line_1) { '1,My Consumer,1,3158419,0,1,2,0,0,0,0,0,0,0,0'}
          let(:line_2) { '2,My Provider,1,3158419,0,2,0,0,0,0,0,0,0,0,0' }
          let(:expected_text) { [line_1, line_2].join("\n") + "\n" }

          xit "returns the relationships as CSV" do
            expect(subject.to_csv).to eq expected_text
          end
        end

      end
    end
  end
end