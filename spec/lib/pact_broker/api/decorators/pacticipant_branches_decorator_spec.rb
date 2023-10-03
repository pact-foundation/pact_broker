require "pact_broker/api/decorators/pacticipant_branches_decorator"

module PactBroker
  module Api
    module Decorators
      describe PacticipantBranchesDecorator do
        it "ensures the pacticipant is eager loaded for the branches collection" do
          expect(PacticipantBranchesDecorator.eager_load_associations).to include :pacticipant
        end

        describe "to_json" do
          let(:branch_1) { instance_double("PactBroker::Versions::Branch", name: "main", pacticipant: pacticipant_1, created_at: td.in_utc { DateTime.new(2020, 1, 1) }  ) }
          let(:pacticipant_1) { instance_double("PactBroker::Domain::Pacticipant", name: "Foo") }
          let(:branches) { [branch_1] }
          let(:options) do
            {
              user_options: {
                pacticipant: pacticipant_1,
                base_url: "http://example.org",
                request_url: "http://example.org/pacticipants/Foo/branches"
              }
            }
          end
          let(:decorator) { PacticipantBranchesDecorator.new(branches) }

          subject { JSON.parse(decorator.to_json(options)) }

          it "generates json" do
            Approvals.verify(subject, :name => "pacticipant_branches_decorator", format: :json)
          end
        end
      end
    end
  end
end
