require "pact_broker/pacts/generate_interaction_sha"

module PactBroker
  module Pacts
    describe GenerateInteractionSha do
      describe ".call" do
        let(:interaction_hash) do
          {
            "description" => "foo",
            "providerStates" => [
              "name" => "bar",
              "params" => {
                "wiffle" => "bar",
                "meep" => "eek"
              }
            ]
          }
        end

        let(:interaction_hash_with_different_key_order) do
          {
            "providerStates" => [
              "name" => "bar",
              "params" => {
                "meep" => "eek",
                "wiffle" => "bar"
              }
            ],
            "description" => "foo"
          }
        end

        subject { GenerateInteractionSha.call(interaction_hash) }

        it "generates a SHA based on the sorted keys" do
          expect(subject).to eq "57d06e151eca35083e4d6b585b4d4fab2e2ed6b7"
        end

        it "generates the same SHA if the keys are ordered differently" do
          expect(subject).to eq GenerateInteractionSha.call(interaction_hash_with_different_key_order)
        end
      end
    end
  end
end
