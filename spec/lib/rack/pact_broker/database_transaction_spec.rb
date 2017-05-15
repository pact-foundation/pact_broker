require 'tasks/database'
require 'rack/pact_broker/database_transaction'

module Rack
  module PactBroker
    describe DatabaseTransaction, no_db_clean: true do

      before do
        ::PactBroker::Database.truncate
      end

      after do
        ::PactBroker::Database.truncate
      end

      let(:api) do
        ->(env) { ::PactBroker::Domain::Pacticipant.create(name: 'Foo'); [500, {}, []] }
      end

      let(:api_with_transaction) do
        ::Rack::PactBroker::DatabaseTransaction.new(api, ::PactBroker::DB.connection)
      end

      subject { self.send(http_method, "/") }

      context "for get requests" do
        let(:app) { api_with_transaction }

        let(:http_method) { :get }
        it "does not use a transaction" do
          expect { subject }.to change { ::PactBroker::Domain::Pacticipant.count }.by(1)
        end
      end

      [:post, :put, :patch, :delete].each do | http_meth |
        let(:http_method) { http_meth }
        context "for #{http_meth} requests" do
          it "uses a transaction and rollsback if there is a 500 error" do
            expect { subject }.to change { ::PactBroker::Domain::Pacticipant.count }.by(0)
          end
        end
      end
    end
  end
end
