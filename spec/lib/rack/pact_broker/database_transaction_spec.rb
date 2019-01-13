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

      subject { self.send(http_method, "/") }

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

      describe "setting the database connector" do
        let(:api) { double('api', call: [200, {}, []]) }

        it "sets a database connector for use in jobs scheduled by this request" do
          expect(api).to receive(:call) do | env |
            expect(Thread.current[:pact_broker_thread_data].database_connector).to_not be nil
            [200, {}, []]
          end

          subject
        end

        it "clears it after the request" do
          subject
          expect(Thread.current[:pact_broker_thread_data].database_connector).to be nil
        end

        context "when other middleware sets the database connector" do
          before do
            Thread.current[:pact_broker_thread_data] = OpenStruct.new(database_connector: other_database_connector)
          end

          let(:other_database_connector) { ->(&block) { block.call } }

          it "does not override it" do
            expect(api).to receive(:call) do | env |
              expect(Thread.current[:pact_broker_thread_data].database_connector).to eq other_database_connector
              [200, {}, []]
            end

            subject
          end

          it "does not clear it after the request" do
            subject
            expect(Thread.current[:pact_broker_thread_data].database_connector).to_not be nil
          end
        end
      end
    end
  end
end
