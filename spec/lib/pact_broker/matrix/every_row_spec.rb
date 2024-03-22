require "pact_broker/matrix/every_row"
require "pact_broker/matrix/resolved_selector"

module PactBroker
  module Matrix
    describe EveryRow do
      let(:foo) { PactBroker::Domain::Pacticipant.where(name: "Foo").single_record }
      let(:bar) { PactBroker::Domain::Pacticipant.where(name: "Bar").single_record }
      let(:wiffle) { PactBroker::Domain::Pacticipant.where(name: "Wiffle").single_record }

      describe "matching_selectors" do
        before do
          td.create_pact_with_verification("Foo", "1", "Bar", "2")
            .create_consumer_version("2")
            .create_pact
            .create_provider("Wiffle")
            .create_pact
            .create_verification(provider_version: "5")
        end

        let(:selector_1) do
          PactBroker::Matrix::ResolvedSelector.for_pacticipant(foo, PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "Foo"), :specified, false)
        end

        let(:selector_2) do
          PactBroker::Matrix::ResolvedSelector.for_pacticipant(bar, PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "Bar"), :specified, false)
        end

        let(:selectors) { [selector_1, selector_2] }

        subject { EveryRow.matching_selectors(selectors, limit: 100).all }

        let(:un_verified_row) { subject.find{ |r| r.provider_id == bar.id && !r.has_verification? } }
        let(:verified_row) { subject.find{ |r| r.provider_id == bar.id && r.has_verification? } }

        it "includes the verified and unverified rows" do
          expect(subject.size).to eq 2
          expect(un_verified_row).to_not be nil
          expect(verified_row).to_not be nil
        end
      end

      describe "eager_all_the_things" do
        before do
          td.create_pact_with_verification("Foo", "1", "Bar", "2")
            .create_consumer_version_tag("foo")
            .create_provider_version_tag("foo")
        end

        subject do
          EveryRow
            .default_scope
            .eager_all_the_things
            .all
        end

        it "can eager load all the things" do
          expect(subject.first.provider_version).to_not be nil
          expect(subject.first.provider_version_id).to_not be nil
          expect(subject.first.consumer_version).to_not be nil
          expect(subject.first.consumer_version_id).to_not be nil
          expect(subject.first.provider_version_id).to_not be nil
          expect(subject.first.consumer_version_id).to_not be nil
          expect(subject.first.pact_publication_id).to_not be nil
          expect(subject.first.pact_version_id).to_not be nil
          expect(subject.first.verification_id).to_not be nil
          expect(subject.first.provider).to_not be nil
          expect(subject.first.consumer).to_not be nil
          expect(subject.first.consumer_version).to_not be nil
          expect(subject.first.provider_version).to_not be nil
          expect(subject.first.pact_version).to_not be nil
          expect(subject.first.verification).to_not be nil
          expect(subject.first.pact_revision_number).to_not be nil
          expect(subject.first.verification_number).to_not be nil
          expect(subject.first.consumer_version_tags).to_not be_empty
          expect(subject.first.provider_version_tags).to_not be_empty
        end
      end


      describe "left_outer_join_verifications" do
        before do
          td.create_pact_with_verification("Foo", "1", "Bar", "2")
            .create_provider("Wiffle")
            .create_pact
            .create_verification(provider_version: "5")
        end

        subject do
          EveryRow
            .default_scope
            .all
        end

        it "joins all the verifications" do
          expect(subject.size).to eq 2
          expect(subject.all?(&:has_verification?)).to be true
        end
      end
    end
  end
end
