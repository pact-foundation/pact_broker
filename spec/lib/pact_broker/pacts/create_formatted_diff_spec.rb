require "pact_broker/pacts/create_formatted_diff"
require "pact_broker/project_root"
require 'flamegraph'

module PactBroker
  module Pacts
    describe CreateFormattedDiff do

      it "" do
        content_1 = File.read(PactBroker.project_root.join("b17279757b28c9319366bb129e3eb75bc1c2fe95.json"))
        content_2 = File.read(PactBroker.project_root.join("c31600ae411a29d136acb1e98d6d91841f70f3e6.json"))
        Flamegraph.generate("bethtemp.html") do
          CreateFormattedDiff.call(
            content_1,
            content_2
          )
        end
      end

      describe ".call" do
        let(:pact_content_version_1) do
          hash = load_json_fixture("consumer-provider.json")
          hash["interactions"].first["request"]["method"] = "post"
          hash.to_json
        end

        let(:pact_content_version_2) { load_fixture("consumer-provider.json") }

        subject { CreateFormattedDiff.call(pact_content_version_2, pact_content_version_1) }

        it "returns the formatted diff" do
          expect(subject).to include "interactions"
          expect(subject).to match(/\-.*post/)
          expect(subject).to match(/\+.*get/)
          expect(subject).to_not include "Key"
        end
      end
    end
  end
end
