require "pact_broker/labels/service"

module PactBroker
  module Labels
    describe Service do
      let(:pacticipant_name) { "foo" }
      let(:label_name) { "ios" }
      let(:options) { { pacticipant_name: pacticipant_name, label_name: label_name } }
      let(:pagination_options) { { page_number: 1, page_size: 1 } }

      describe ".get_all_unique_labels" do
        subject { Service.get_all_unique_labels(pagination_options) }

        it "calls the labels repository" do
          expect_any_instance_of(Labels::Repository).to receive(:get_all_unique_labels).with(pagination_options)
          subject
        end
      end

      describe ".create" do
        subject { Service.create(options) }

        # Naughty integration test... didn't seem much point unit testing this
        it "creates the new tag" do
          expect(subject.name).to eq label_name
          expect(subject.pacticipant.name).to eq pacticipant_name
        end
      end

      describe "delete" do
        it "calls delete on the label repository" do
          allow_any_instance_of(Labels::Repository).to receive(:delete).with(options)
          Service.delete(options)
        end
      end
    end
  end
end
