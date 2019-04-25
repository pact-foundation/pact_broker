require 'pact_broker/pacts/generate_interaction_sha'

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
                "wiffle" => "bar",
                "meep" => "eek"
              }
            ],
            "description" => "foo"
          }
        end

        let(:interaction_hash_with_different_params_order) do
          {
            "description" => "foo",
            "providerStates" => [
              "name" => "bar",
              "params" => {
                "meep" => "eek",
                "wiffle" => "bar"
              }
            ]
          }
        end

        subject { GenerateInteractionSha.call(interaction_hash) }

        it "generates a SHA based on the sorted keys" do
          expect(subject).to eq "5ec1cc12132d3437a5a2ced5537cdab2d4f44521"
        end

        it "generates the same SHA if the top level keys are ordered differently" do
          expect(subject).to eq GenerateInteractionSha.call(interaction_hash_with_different_key_order)
        end

        # This could be a whole lot smarter, but I'm not sure it's worth it.
        # eg. order of provider state params doesn't matter, but the ordering
        # of the provider states themselves may... who knows.
        # Let's not try and be too smart about it until we have a use case to flesh it out.
        it "generates a different SHA if any of the other keys are ordered differently" do
          expect(subject).to_not eq GenerateInteractionSha.call(interaction_hash_with_different_params_order)
        end
      end
    end
  end
end
