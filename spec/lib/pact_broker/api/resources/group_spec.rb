require 'spec_helper'
require 'pact_broker/api/resources/group'
require 'pact_broker/groups/service'
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
        let(:pacticipant) { double('pacticipant')}

        before do
          allow(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).and_return(pacticipant)
          allow(PactBroker::Groups::Service).to receive(:find_group_containing).and_return(group)
          allow(PactBroker::Api::Decorators::RelationshipsCsvDecorator).to receive(:new).and_return(decorator)
          allow(decorator).to receive(:to_csv).and_return(csv)
        end

        subject { get "/groups/Some%20Service", '', {"HTTP_X_My_App_Version" => '2'} }

        context "when the pacticipant exists" do

          it "looks up the pacticipant by name" do
            expect(PactBroker::Pacticipants::Service).to receive(:find_pacticipant_by_name).with('Some Service')
            subject
          end

          it "finds the group containing the pacticipant" do
            expect(PactBroker::Groups::Service).to receive(:find_group_containing).with(pacticipant)
            subject
          end

          it "creates a CSV from the group" do
            expect(PactBroker::Api::Decorators::RelationshipsCsvDecorator).to receive(:new).with(group)
            subject
          end

          it "returns a 200 response" do
            subject
            expect(last_response.status).to eq 200
          end

          it "returns a CSV content type" do
            subject
            expect(last_response.headers['Content-Type']).to eq 'text/csv;charset=utf-8'
          end

          it "returns a CSV of pacticipants that are in the same group as the given pacticipant" do
            subject
            expect(last_response.body).to eq csv
          end

        end

        context "when the pacticipant does not exist" do
          let(:pacticipant) { nil }

          it "returns a 404 response" do
            subject
            expect(last_response.status).to eq 404
          end
        end


      end

    end
  end

end
