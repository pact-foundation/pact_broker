require "spec/support/test_data_builder"
require "pact_broker/pacts/merger"
require "json"

module PactBroker
  module Pacts
    describe Merger do
      let(:example_pact) { load_json_fixture("consumer-provider.json") }
      let(:example_interaction) do
        {
          "description" => "some description",
          "provider_state" => nil,
          "request" => {
            "method" => "get",
            "path" => "/cash_money",
            "headers" => {
              "Content-Type" => "application/json"
            }
          },
          "response" => {
            "status" => 200,
            "body" => "$$$$$$$$",
            "headers" => {
              "Content-Type" => "application/json"
            }
          }
        }
      end

      describe "#merge" do
        let(:pact_to_merge) { load_json_fixture("consumer-provider.json") }

        it "merges two pacts" do
          pact_to_merge["interactions"] << example_interaction
          result = merge_pacts(example_pact, pact_to_merge)
          expect(result["interactions"]).to match_array(example_pact["interactions"].push(example_interaction))
        end

        it "is idempotent" do
          pact_to_merge["interactions"] << example_interaction
          first_result = merge_pacts(example_pact, pact_to_merge)
          second_result = merge_pacts(first_result, pact_to_merge)
          expect(first_result).to contain_hash second_result
        end

        it "overwrites identical interactions" do
          pact_to_merge["interactions"][0]["response"]["body"] = "changed!"
          result = merge_pacts(example_pact, pact_to_merge)

          expect(result["interactions"].length).to eq example_pact["interactions"].length
          expect(result["interactions"].first["response"]["body"]).to eq "changed!"
        end

        it "appends interactions with a different provider state" do
          pact_to_merge["interactions"][0]["provider_state"] = "upside down"

          result = merge_pacts(example_pact, pact_to_merge)
          expect(result["interactions"].length).to eq example_pact["interactions"].length + 1
        end

        it "appends interactions with a different description" do
          pact_to_merge["interactions"][0]["description"] = "getting $$$"

          result = merge_pacts(example_pact, pact_to_merge)
          expect(result["interactions"].length).to eq example_pact["interactions"].length + 1
        end

        it "matches same provider state when is in v2 format" do
          example_pact["interactions"][0]["providerState"] = "something in the way"
          pact_to_merge["interactions"][0]["providerState"] = "something in the way"
          pact_to_merge["interactions"][0]["response"]["body"] = "changed!"

          result = merge_pacts(example_pact, pact_to_merge)

          expect(result["interactions"].length).to eq example_pact["interactions"].length
          expect(result["interactions"].first["response"]["body"]).to eq "changed!"
        end

        it "supports merging when provider state is in either v2 or v1 format" do
          example_pact["interactions"][0]["provider_state"] = "system must resist"
          pact_to_merge["interactions"][0]["providerState"] = "system must resist"
          pact_to_merge["interactions"][0]["response"]["body"] = "changed!"

          result = merge_pacts(example_pact, pact_to_merge)

          expect(result["interactions"].length).to eq example_pact["interactions"].length
          expect(result["interactions"].first["response"]["body"]).to eq "changed!"
        end

        it "supports merging when provider state is in v3 format with providerStates" do
          example_pact["interactions"][0]["providerStates"] = [{ name: "a state" }]
          pact_to_merge["interactions"][0]["providerStates"] = [{ name: "a state" }]
          pact_to_merge["interactions"][0]["response"]["body"] = "changed!"

          result = merge_pacts(example_pact, pact_to_merge)

          expect(result["interactions"].length).to eq example_pact["interactions"].length
          expect(result["interactions"].first["response"]["body"]).to eq "changed!"
        end

        # helper that lets these specs deal with hashes instead of JSON strings
        def merge_pacts(a, b, return_hash = true)
          result = PactBroker::Pacts::Merger.merge_pacts(a.to_json, b.to_json)

          return_hash ? JSON.parse(result) : result
        end
      end

      describe "#conflict?" do
        let(:pact_to_compare) { load_json_fixture("consumer-provider.json") }

        it "returns false if interactions have different descriptions" do
          pact_to_compare["interactions"][0]["description"] = "something else"

          expect(compare_pacts(example_pact, pact_to_compare)).to eq false
        end

        it "returns false if interactions have different provider states" do
          pact_to_compare["interactions"][0]["provider_state"] = "some other thing"
          expect(compare_pacts(example_pact, pact_to_compare)).to eq false
        end

        context "when interactions have the same desc/state" do
          it "returns false if request parameters are the same" do
            expect(compare_pacts(example_pact, pact_to_compare)).to eq false
          end

          it "returns true if requests have a different query" do
            pact_to_compare["interactions"][0]["request"]["query"] = "foo=bar&baz=qux"
            expect(compare_pacts(example_pact, pact_to_compare)).to eq true
          end

          it "returns true if requests have a different body" do
            pact_to_compare["interactions"][0]["request"]["body"] = { "something" => { "nested" => "deeply" } }
            expect(compare_pacts(example_pact, pact_to_compare)).to eq true
          end

          it "returns true if request method is different" do
            pact_to_compare["interactions"][0]["request"]["method"] = "post"
            expect(compare_pacts(example_pact, pact_to_compare)).to eq true
          end

          it "returns true if request path is different" do
            pact_to_compare["interactions"][0]["request"]["path"] = "/new_path"
            expect(compare_pacts(example_pact, pact_to_compare)).to eq true
          end

          it "returns true if request headers are different" do
            pact_to_compare["interactions"][0]["request"]["headers"]["Content-Type"] = "text/html"
            expect(compare_pacts(example_pact, pact_to_compare)).to eq true
          end

          it "returns true if request has additional headers" do
            pact_to_compare["interactions"][0]["request"]["headers"]["Accept"] = "text/html"
            expect(compare_pacts(example_pact, pact_to_compare)).to eq true
          end

          it "returns true if request has missing headers" do
            pact_to_compare["interactions"][0]["request"]["headers"].delete("Content-Type")
            expect(compare_pacts(example_pact, pact_to_compare)).to eq true
          end

          it "returns true if the existing pact has no interactions and the new one does" do
            example_pact["interactions"] = nil
            expect(compare_pacts(example_pact, pact_to_compare)).to eq true
          end

          it "returns true if the new pact has no interactions and the existing one does" do
            pact_to_compare["interactions"] = nil
            expect(compare_pacts(example_pact, pact_to_compare)).to eq true
          end
        end

        def compare_pacts(a, b)
          PactBroker::Pacts::Merger.conflict?(a.to_json, b.to_json)
        end

      describe "with Janus contracts" do
        let(:features) { { janus: true } }
        let(:contract) { load_json_fixture("janus-contract.json") }
        let(:other_contract) { JSON.parse(contract.to_json) }
        let(:new_interaction) do
          JSON.parse(contract["interactions"].first.to_json).merge("description" => "a request for another order")
        end

        before do
          allow(PactBroker.configuration).to receive(:features).and_return(features)
        end

        def merge(a, b)
          JSON.parse(Merger.merge_pacts(a.to_json, b.to_json))
        end

        def conflict?(a, b)
          Merger.conflict?(a.to_json, b.to_json)
        end

        describe "#merge_pacts" do
          it "appends an interaction of a new identity" do
            other_contract["interactions"] = [new_interaction]
            expect(merge(contract, other_contract)["interactions"]).to eq contract["interactions"] + [new_interaction]
          end

          it "replaces an interaction of the same description and states" do
            other_contract["interactions"] = [other_contract["interactions"].first]
            other_contract["interactions"].first["parts"]["request"]["path"]["example"] = "/orders/43"
            merged = merge(contract, other_contract)
            expect(merged["interactions"]).to eq [other_contract["interactions"].first, contract["interactions"].last]
          end

          it "keeps two interactions with the same description and different states" do
            other_contract["interactions"] = [other_contract["interactions"].first]
            other_contract["interactions"].first["states"] = []
            expect(merge(contract, other_contract)["interactions"].size).to eq 3
          end

          it "replaces a pact with a Janus contract, rather than merging the two" do
            expect(merge(load_json_fixture("consumer-provider.json"), contract)).to eq contract
          end
        end

        describe "#conflict?" do
          it "is false for the same contract, whatever _id the broker gave its interactions" do
            stored = JSON.parse(contract.to_json)
            stored["interactions"].each { |i| i["_id"] = "1234" }
            expect(conflict?(stored, contract)).to be false
          end

          it "is false for an interaction of a new identity" do
            other_contract["interactions"] = [new_interaction]
            expect(conflict?(contract, other_contract)).to be false
          end

          it "is true for an interaction of the same identity recorded differently" do
            other_contract["interactions"].first["parts"]["response"] = {}
            expect(conflict?(contract, other_contract)).to be true
          end

          it "is true for a Janus contract and a pact" do
            expect(conflict?(load_json_fixture("consumer-provider.json"), contract)).to be true
            expect(conflict?(contract, load_json_fixture("consumer-provider.json"))).to be true
          end
        end

        context "with the janus feature off" do
          let(:features) { {} }

          it "merges as before, by description alone, since a contract has no provider state a pact names" do
            other_contract["interactions"] = [other_contract["interactions"].first]
            other_contract["interactions"].first["states"] = []
            expect(merge(contract, other_contract)["interactions"].size).to eq 2
          end
        end
      end
      end
    end
  end
end
