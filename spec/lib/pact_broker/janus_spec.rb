require "pact_broker/janus"

module PactBroker
  describe Janus do
    let(:contract) { load_json_fixture("janus-contract.json") }
    let(:features) { { janus: true } }

    before do
      allow(PactBroker.configuration).to receive(:features).and_return(features)
    end

    describe ".contract?" do
      it "is true for a document whose $format is janus-contract/1" do
        expect(Janus.contract?(contract)).to be true
      end

      it "reads a document parsed with symbol keys" do
        expect(Janus.contract?(JSON.parse(contract.to_json, symbolize_names: true))).to be true
      end

      it "is false for a pact" do
        expect(Janus.contract?(load_json_fixture("consumer-provider.json"))).to be false
      end

      it "is false for a major the broker does not read" do
        expect(Janus.contract?(contract.merge("$format" => "janus-contract/2"))).to be false
      end

      it "is false for something that is not a hash" do
        expect(Janus.contract?([contract])).to be false
      end

      context "with the janus feature off" do
        let(:features) { {} }

        it "is false" do
          expect(Janus.contract?(contract)).to be false
        end
      end

      context "outside production, with the janus feature off" do
        let(:features) { {} }

        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with("RACK_ENV").and_return("development")
        end

        it "is still false, because the feature is read from the configuration alone" do
          expect(Janus.contract?(contract)).to be false
        end
      end
    end

    describe ".specifications" do
      it "accepts janus with the feature on" do
        expect(Janus.specifications).to eq ["pact", "janus"]
      end

      context "with the janus feature off" do
        let(:features) { {} }

        it "accepts only pact" do
          expect(Janus.specifications).to eq ["pact"]
        end
      end
    end

    describe ".interaction_identity" do
      it "is the description and the states" do
        interaction = contract["interactions"].first
        expect(Janus.interaction_identity(interaction)).to eq ["a request for an order", [{ "name" => "an order exists", "params" => { "id" => "42" } }]]
      end

      it "treats no states as an empty list" do
        expect(Janus.interaction_identity({ "description" => "x" })).to eq ["x", []]
      end
    end

    describe ".message?" do
      it "is true for an emissive interaction" do
        expect(Janus.message?(contract["interactions"].last)).to be true
      end

      it "is false for a passive one" do
        expect(Janus.message?(contract["interactions"].first)).to be false
      end
    end
  end
end
