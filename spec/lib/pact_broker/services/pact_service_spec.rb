require 'spec_helper'
require 'pact_broker/services/pact_service'

module PactBroker

  module Services
    module PactService

      describe "#pact_has_changed_since_previous_version?" do

        let(:json_content) { { 'some' => 'json'}.to_json }
        let(:pact) { instance_double(PactBroker::Models::Pact, json_content: json_content)}

        before do
          allow_any_instance_of(Repositories::PactRepository).to receive(:find_previous_pact).and_return(previous_pact)
        end

        subject { PactService.pact_has_changed_since_previous_version? pact }

        context "when a previous pact is found" do
          let(:previous_pact) { instance_double(PactBroker::Models::Pact, json_content: previous_json_content)}
          let(:previous_json_content) { {'some' => 'json'}.to_json }

          context "when the json_content is the same" do
            it "returns false" do
              expect(subject).to be_falsey
            end
          end

          context "when the json_content is not the same" do
            let(:previous_json_content) { {'some-other' => 'json'}.to_json }
            it "returns truthy" do
              expect(subject).to be_truthy
            end
          end
        end

        context "when a previous pact is not found" do
          let(:previous_pact) { nil }
          it "returns false" do
            expect(subject).to be_falsey
          end
        end

      end

    end
  end
end