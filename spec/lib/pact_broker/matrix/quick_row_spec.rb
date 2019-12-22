require 'pact_broker/matrix/quick_row'
require 'pact_broker/matrix/resolved_selector'
require 'pact_broker/matrix/quick_row_2'

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
        rows = QuickRow.consumer_id(a_id).eager(:consumer).eager(:verification).all
        expect(rows.first.consumer).to be rows.last.consumer
        expect(rows.first.verification).to_not be nil
        expect(rows.first.consumer_name).to_not be nil
        expect(rows.first.provider_name).to_not be nil
      end

      describe "new_query" do
        # ServiceA v 5 has been verified by ServiceB v 100
        # but ServiceB v 100 has only been verified by ServiceA v 99.
        # It's missing a verification from ServiceA v5.
        before do
          td.create_pact_with_verification("ServiceA", "5", "ServiceB", "100")
            .create_pact_with_verification("ServiceB", "100", "ServiceA", "99")
            .create_pact_with_verification("ServiceA", "5", "ServiceZ", "3")
        end

        def shorten_row row
          "#{row[:consumer_name]}#{row[:consumer_version_number]} #{row[:provider_name]}#{row[:provider_version_number] || '?'}"
        end

        def shorten_rows rows
          rows.collect{ |r| shorten_row(r) }
        end

        let!(:pact_a) { td.create_pact_with_verification("ServiceA", "5", "ServiceB", "100").and_return(:pact) }
        let!(:verification_a) { td.and_return(:verification) }
        let!(:pact_b) { td.create_pact_with_verification("ServiceB", "100", "ServiceA", "99").and_return(:pact) }
        let!(:verification_b) { td.and_return(:verification) }

        let(:service_a) { PactBroker::Domain::Pacticipant.where(name: "ServiceA").single_record }
        let(:service_b) { PactBroker::Domain::Pacticipant.where(name: "ServiceB").single_record }
        let(:version_a) { PactBroker::Domain::Version.where(number: "5").single_record }
        let(:version_b) { PactBroker::Domain::Version.where(number: "100").single_record }

        let(:selectors) do
          [
            PactBroker::Matrix::ResolvedSelector.for_pacticipant_and_version(service_a, version_a, nil, nil, {}, :specified),
            PactBroker::Matrix::ResolvedSelector.for_pacticipant_and_version(service_b, version_b, nil, nil, {}, :specified)
          ]
        end

        subject { QuickRow2.matching_selectors(selectors).all }
        let(:subject_hashes) { subject.collect(&:to_hash) }

        it "" do
          tp subject_hashes, :consumer_id, :consumer_version_number, :provider_id, :provider_version_id

          expect(subject.size).to be 2
          expect(subject_hashes.collect(&:to_hash)).to include_hash_matching(
            consumer_name: "ServiceA",
            consumer_version_number: "5",
            provider_name: "ServiceB",
            provider_version_number: "100"
          )
          expect(subject_hashes.collect(&:to_hash)).to include_hash_matching(
            consumer_name: "ServiceB",
            consumer_version_number: "100",
            provider_name: "ServiceA",
            provider_version_number: nil
          )
        end

        context "with one selector" do
          let(:selectors) do
            [
              PactBroker::Matrix::ResolvedSelector.for_pacticipant_and_version(service_b, version_b, nil, nil, {}, :specified),
            ]
          end

          it "" do
            tp subject_hashes, :consumer_name, :consumer_version_number, :provider_name, :provider_version_number
            expect(subject.size).to be 2
          end
        end
      end
    end
  end
end
