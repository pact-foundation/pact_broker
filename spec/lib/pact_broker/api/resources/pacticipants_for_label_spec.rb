require "pact_broker/api/resources/pacticipants_for_label"

module PactBroker
  module Api
    module Resources
      describe PacticipantsForLabel do
        describe "GET" do
          let(:query) do
            {
              "size" => "10",
              "page" => "1",
              "q" => "search"
            }
          end
          let(:headers) do
            {
              "HTTP_ACCEPT" => "application/hal+json",
            }
          end
          let(:pacticipants) do
            [
              PactBroker::Domain::Pacticipant.new(name: "Pacticipant 1"),
              PactBroker::Domain::Pacticipant.new(name: "Pacticipant 2"),
            ]
          end

          before do
            allow(PactBroker::Pacticipants::Service).to receive(:find_all_pacticipants).and_return(pacticipants)
          end

          subject { get("/pacticipants/label/ios", query, headers) }

          it "calls find_all_pacticipants with the label name, query string and pagination options" do
            expect(PactBroker::Pacticipants::Service).to receive(:find_all_pacticipants).
              with(
                { label_name: "ios", query_string: "search" },
                { page_number: 1, page_size: 10 },
                PactBroker::Api::Decorators::PacticipantsDecorator.eager_load_associations
              ).
              and_return(pacticipants)
            subject
          end

          it "returns a 200" do
            expect(subject.status).to eq 200
          end

          context "without the q param" do
            let(:query) { { "size" => "10", "page" => "1" } }

            it "calls find_all_pacticipants without a query string" do
              expect(PactBroker::Pacticipants::Service).to receive(:find_all_pacticipants).
                with(
                  { label_name: "ios" },
                  { page_number: 1, page_size: 10 },
                  anything
                ).
                and_return(pacticipants)
              subject
            end
          end

          context "with invalid pagination params" do
            let(:query) do
              {
                "size" => "0",
                "page" => "0",
              }
            end

            it_behaves_like "an invalid pagination params response"
          end
        end
      end
    end
  end
end
