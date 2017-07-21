require 'spec_helper'
require 'pact_broker/api/decorators/pacticipant_decorator'
require 'pact_broker/domain/pacticipant'

module PactBroker

  module Api

    module Decorators

      describe PacticipantDecorator do

        let(:pacticipant) do
          TestDataBuilder.new
            .create_pacticipant('Name')
            .create_label('foo')
            .and_return(:pacticipant)
        end

        let(:created_at) { Time.new(2014, 3, 4) }
        let(:updated_at) { Time.new(2014, 3, 5) }

        before do
          pacticipant.created_at = created_at
          pacticipant.updated_at = updated_at
        end

        subject { JSON.parse PacticipantDecorator.new(pacticipant).to_json(user_options: {base_url: 'http://example.org'}), symbolize_names: true }

        it "includes timestamps" do
          expect(subject[:createdAt]).to eq created_at.xmlschema
          expect(subject[:updatedAt]).to eq updated_at.xmlschema
        end

        it "includes embedded labels" do
          expect(subject[:_embedded][:labels].first).to include name: 'foo'
          expect(subject[:_embedded][:labels].first[:_links][:self][:href]).to match %r{http://example.org/.*foo}
        end
      end
    end
  end
end
