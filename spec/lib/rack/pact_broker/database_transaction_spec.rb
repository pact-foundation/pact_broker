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

      let(:headers) { {} }

      let(:api) do
        ->(env) { ::PactBroker::Domain::Pacticipant.create(name: 'Foo'); [500, headers, []] }
      end

      let(:app) do
        ::Rack::PactBroker::DatabaseTransaction.new(api, ::PactBroker::DB.connection)
      end

      let(:rack_headers) { {} }

      subject { self.send(http_method, "/", rack_headers) }

      it "sets the pactbroker.database_connector on the env" do
        actual_env = nil
        allow(api).to receive(:call) do | env |
          actual_env = env
          [200, {}, {}]
        end
        subject
        expect(actual_env).to have_key("pactbroker.database_connector")
      end

      context "when the pactbroker.database_connector already exists" do
        let(:rack_headers) { { "pactbroker.database_connector" => double('existing database connector') } }
        let(:existing_database_connector) { double('existing database connector') }

        it "does not overwrite it", pending: "key is not showing up in rack env for some reason" do
          actual_env = nil
          allow(api).to receive(:call) do | env |
            actual_env = env
            [200, {}, {}]
          end
          subject
          expect(actual_env["pactbroker.database_connector"]).to be existing_database_connector
        end
      end

      context "for get requests" do
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

      context "when there is an error but the resource sets the no rollback header" do
        let(:headers) { {::PactBroker::DO_NOT_ROLLBACK => 'true'} }
        let(:http_method) { :post }

        it "does not roll back" do
          expect { subject }.to change { ::PactBroker::Domain::Pacticipant.count }.by(1)
        end
      end
    end
  end
end
