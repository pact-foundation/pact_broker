require "pact_broker/pacts/create_formatted_diff"

module PactBroker
  module Pacts
    describe CreateFormattedDiff do
      describe ".call" do
        let(:previous_content) { { consumer: { name: "Foo" }, provider: { name: "Bar" }, interactions: [interaction] }.to_json }
        let(:content) { { consumer: { name: "Foo" }, provider: { name: "Bar" }, interactions: [changed_interaction] }.to_json }
        let(:interaction) { { description: "a request", request: { method: "post", path: "/" }, response: { status: 200 } } }
        let(:changed_interaction) { { description: "a request", request: { method: "get", path: "/" }, response: { status: 200 } } }

        subject { CreateFormattedDiff.call(content, previous_content) }

        it "marks the previous content with - and the current content with +" do
          expect(subject).to include "-        \"method\": \"post\""
          expect(subject).to include "+        \"method\": \"get\""
        end

        it "shows unchanged lines as context" do
          expect(subject).to include " \"description\": \"a request\""
        end

        it "starts with a hunk header" do
          expect(subject).to start_with "@@ "
        end

        it "does not print a key or legend" do
          expect(subject).to_not include "Key"
        end

        context "when the content is identical" do
          let(:changed_interaction) { interaction }

          it "returns an empty string" do
            expect(subject).to eq ""
          end
        end

        context "when an interaction is added" do
          let(:content) { { consumer: { name: "Foo" }, provider: { name: "Bar" }, interactions: [interaction, added] }.to_json }
          let(:added) { { description: "another request", request: { method: "get", path: "/other" }, response: { status: 404 } } }

          it "shows the added interaction as + lines" do
            expect(subject).to include "+      \"description\": \"another request\""
            expect(subject).to_not match(/^-/)
          end
        end

        context "when a key is added" do
          let(:changed_interaction) { { description: "a request", request: { method: "post", path: "/", headers: { "Accept" => "application/json" } }, response: { status: 200 } } }

          it "shows the added key as + lines" do
            expect(subject).to include "+        \"headers\": {"
            expect(subject).to include "+          \"Accept\": \"application/json\""
            expect(subject).to_not match(/^-/)
          end
        end

        context "when raw is true" do
          let(:interaction) { { description: "a request", request: { method: "post", path: "/" }, response: { status: 200 }, _id: "abc" } }
          let(:changed_interaction) { interaction.merge(_id: "def") }

          subject { CreateFormattedDiff.call(content, previous_content, raw: true) }

          it "does not strip ids" do
            expect(subject).to include "\"_id\""
          end

          context "when raw is false" do
            subject { CreateFormattedDiff.call(content, previous_content, raw: false) }

            it "strips ids and finds no difference" do
              expect(subject).to eq ""
            end
          end
        end
      end
    end
  end
end
