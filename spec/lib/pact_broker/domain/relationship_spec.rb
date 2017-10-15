require 'pact_broker/domain/relationship'

module PactBroker
  module Domain
    describe Relationship do
      describe "#last_webhook_execution_date" do
        let(:webhook_execution_1) { double('webhook_execution', created_at: DateTime.new(2013)) }
        let(:webhook_execution_2) { double('webhook_execution', created_at: DateTime.new(2015)) }

        let(:webhook_executions) { [webhook_execution_1, webhook_execution_2] }

        before do
          allow(webhook_executions).to receive(:sort).and_return(webhook_executions)
        end

        subject { Relationship.create(nil, nil, nil, true, nil, [], webhook_executions) }

        it "returns the created_at date of the last execution" do
          expect(subject.last_webhook_execution_date).to eq DateTime.new(2015)
        end
      end
    end
  end
end
