require 'pact_broker/matrix/repository'

module PactBroker
  module Matrix
    describe Repository do
      let(:td) { TestDataBuilder.new}

      describe "find_integrations" do
        before do
          td.create_pact_with_hierarchy("foo", "1", "bar")
            .create_provider("baz")
            .create_pact
            .use_consumer("baz")
            .create_consumer_version("3")
            .create_provider("wiffle")
            .create_pact
        end

        subject { Repository.new.find_integrations(["foo"]).sort }

        context "with only one pacticipant name" do
          it "returns all the integrations that the pacticipant with the given name has" do
            expect(subject.first.consumer_name).to eq "foo"
            expect(subject.first.provider_name).to eq "bar"
            expect(subject.last.consumer_name).to eq "foo"
            expect(subject.last.provider_name).to eq "baz"
            expect(subject.size).to eq 2
          end
        end

        context "with the names of two pacticipants that are integrated" do
          subject { Repository.new.find_integrations(["foo", "bar"]).sort }

          it "returns only that integration" do
            expect(subject.first.consumer_name).to eq "foo"
            expect(subject.first.provider_name).to eq "bar"
            expect(subject.size).to eq 1
          end
        end

        context "with the names of two pacticipants that aren't integrated" do
          subject { Repository.new.find_integrations(["foo", "wiffle"]).sort }

          it "returns an empty array" do
            expect(subject).to eq []
          end
        end
      end
    end
  end
end
