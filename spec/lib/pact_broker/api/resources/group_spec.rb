require 'spec_helper'
require 'pact_broker/api/resources/group'
require 'rack/test'

module PactBroker::Api

  module Resources

    describe Group do

      include Rack::Test::Methods

      let(:app) { PactBroker::API }

      describe "GET" do

        let(:group) { double('group') }
        let(:decorator) { instance_double(PactBroker::Api::Decorators::RelationshipsCsvDecorator) }
        let(:csv) { 'csv' }

        before do
          allow(PactBroker::Services::GroupService).to receive(:find_group_containing).and_return(group)
          allow(PactBroker::Api::Decorators::RelationshipsCsvDecorator).to receive(:new).and_return(decorator)
          allow(decorator).to receive(:to_csv).and_return(csv)
        end

        it "returns a CSV of pacticipants that are in the same group as the given pacticipant" do
          get "/groups/Some%20Service"
          expect(last_response.body).to eq csv
        end

        it "returns a CSV content type" do
          get "/groups/Some%20Service"
          expect(last_response.headers['Content-Type']).to eq 'text/csv'
        end

        it "creates a CSV from the group" do
          expect(PactBroker::Api::Decorators::RelationshipsCsvDecorator).to receive(:new).with(group)
          get "/groups/Some%20Service"
        end
      end

    end
  end

end
