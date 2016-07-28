require 'spec_helper'
require 'spec/support/provider_state_builder'
require 'pact_broker/pact_merger'
require 'json'

module PactBroker
  describe PactMerger do
    let(:example_pact) { load_json_fixture('consumer-provider.json') }
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

    before :each do
      @pact_to_merge = load_json_fixture('consumer-provider.json')
    end

    it "merges two pacts" do
      @pact_to_merge["interactions"] << example_interaction
      result = merge_pacts(example_pact, @pact_to_merge)
      expect(result["interactions"]).to match_array(example_pact["interactions"].push(example_interaction))
    end

    it "is idempotent" do
      @pact_to_merge["interactions"] << example_interaction
      first_result = merge_pacts(example_pact, @pact_to_merge)
      second_result = merge_pacts(first_result, @pact_to_merge)
      expect(first_result).to contain_hash second_result
    end

    it "overwrites identical interactions" do
      @pact_to_merge["interactions"][0]["response"]["body"] = "changed!"
      result = merge_pacts(example_pact, @pact_to_merge)

      expect(result["interactions"].length).to eq example_pact["interactions"].length
      expect(result["interactions"].first["response"]["body"]).to eq "changed!"
    end

    it "appends interactions with a different provider state" do
      @pact_to_merge["interactions"][0]["provider_state"] = "upside down"

      result = merge_pacts(example_pact, @pact_to_merge)
      expect(result["interactions"].length).to eq example_pact["interactions"].length + 1
    end

    it "appends interactions with a different description" do
      @pact_to_merge["interactions"][0]["description"] = "getting $$$"

      result = merge_pacts(example_pact, @pact_to_merge)
      expect(result["interactions"].length).to eq example_pact["interactions"].length + 1
    end

    it "appends interactions with a different request method" do
      @pact_to_merge["interactions"][0]["request"]["method"] = "delete"

      result = merge_pacts(example_pact, @pact_to_merge)
      expect(result["interactions"].length).to eq example_pact["interactions"].length + 1
    end

    it "appends interactions with a different request path" do
      @pact_to_merge["interactions"][0]["request"]["path"] = "/decrypt_all_passwords"

      result = merge_pacts(example_pact, @pact_to_merge)
      expect(result["interactions"].length).to eq example_pact["interactions"].length + 1
    end

    it "overwrites interactions which have additional request headers in the new pact" do
      @pact_to_merge["interactions"][0]["request"]["headers"] = { "Accept" => "script/javascript" }
      @pact_to_merge["interactions"][0]["response"]["body"] = "changed!"

      result = merge_pacts(example_pact, @pact_to_merge)
      expect(result["interactions"].length).to eq example_pact["interactions"].length
      expect(result["interactions"].first["response"]["body"]).to eq "changed!"
    end

    it "appends interactions with different request headers" do
      example_pact["interactions"][0]["request"]["headers"] = { "Content-Type" => "script/javascript" }
      @pact_to_merge["interactions"][0]["request"]["headers"] = { "Content-Type" => "ayy/lmao" }

      result = merge_pacts(example_pact, @pact_to_merge)
      expect(result["interactions"].length).to eq example_pact["interactions"].length + 1
    end

    it "appends interactions with fewer request headers" do
      example_pact["interactions"][0]["request"]["headers"] = { "Content-Type" => "script/javascript" }

      result = merge_pacts(example_pact, @pact_to_merge)
      expect(result["interactions"].length).to eq example_pact["interactions"].length + 1
    end

    # helper that lets these specs deal with hashes instead of JSON strings
    def merge_pacts(a, b, return_hash = true)
      result = PactBroker::PactMerger.merge_pacts(a.to_json, b.to_json)

      return_hash ? JSON.parse(result) : result
    end
  end
end
