require 'pact_broker/matrix/quick_row'
require 'pact_broker/matrix/resolved_selector'

module PactBroker
  module Matrix
    describe QuickRow do
      before do
        td.create_pact_with_hierarchy("A", "1", "B")
          .create_verification(provider_version: '1', success: false)
          .create_verification(provider_version: '1', number: 2, success: true)
          .create_verification(provider_version: '2', number: 3, success: true)
          .create_provider("C")
          .create_pact
          .create_verification(provider_version: '1')
          .create_consumer_version("2")
          .create_pact
          .create_verification(provider_version: '3')
          .use_provider("B")
          .create_pact
      end

      it "behaves like a Row, except quicker" do
        a_id = QuickRow.db[:pacticipants].where(name: "A").select(:id).single_record[:id]
        rows = QuickRow.default_scope.where(consumer_id: a_id).eager(:consumer).eager(:verification).all
        expect(rows.first.consumer).to be rows.last.consumer
        expect(rows.first.verification).to_not be nil
        expect(rows.first.consumer_name).to_not be nil
        expect(rows.first.provider_name).to_not be nil
      end
    end
  end
end
