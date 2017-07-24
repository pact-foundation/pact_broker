require 'pact_broker/labels/service'

module PactBroker
  module Labels
    describe Service do
      let(:pacticipant_name) { "foo" }
      let(:label_name) { "ios" }
      let(:options) { {pacticipant_name: pacticipant_name, label_name: label_name}}

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
