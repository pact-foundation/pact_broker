require 'spec_helper'
require 'pact_broker/messages'

module PactBroker
  module Messages


    describe "#potential_duplicate_pacticipant_message" do
      let(:new_name) { 'Contracts' }
      let(:fred) { double('Contracts Service', name: 'Contracts Service') }
      let(:frederich) { double('Accepted Contracts', name: 'Accepted Contracts') }
      let(:potential_duplicate_pacticipants) { [fred, frederich]}

      let(:expected_message) { String.new <<-EOS
This is the first time a pact has been published for "Contracts".
The name "Contracts" is very similar to the following existing consumers/providers:
* Contracts Service
* Accepted Contracts
If you meant to specify one of the above names, please correct the pact configuration, and re-publish the pact.
If the pact is intended to be for a new consumer or provider, please manually create "Contracts" using the following command, and then re-publish the pact:
$ curl -v -XPOST -H "Content-Type: application/json" -d "{\\\"name\\\": \\\"Contracts\\\"}" http://example.org/pacticipants
EOS
      }
      subject { Messages.potential_duplicate_pacticipant_message new_name, potential_duplicate_pacticipants, 'http://example.org' }

      it "returns a message" do
        expect(subject).to eq expected_message
      end
    end
  end
end
