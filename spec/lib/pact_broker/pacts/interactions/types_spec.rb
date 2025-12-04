require "pact_broker/pacts/interactions/types"

module PactBroker
  module Pacts
    module Interactions
      describe Types do
        describe "#has_messages?" do
          context "when pact specification version is 4" do
            let(:pact_hash) do
              {
                "consumer" => { "name" => "Foo" },
                "provider" => { "name" => "Bar" },
                "interactions" => [
                  {
                    "_id" => "msg1",
                    "type" => "Asynchronous/Messages",
                    "description" => "a message",
                    "contents" => { "foo" => "bar" }
                  },
                  {
                    "_id" => "http1",
                    "type" => "Synchronous/HTTP",
                    "description" => "an http request",
                    "request" => { "method" => "GET", "path" => "/foo" },
                    "response" => { "status" => 200 }
                  },
                  {
                    "_id" => "msg2",
                    "type" => "Asynchronous/Messages",
                    "description" => "another message",
                    "contents" => { "baz" => "qux" }
                  }
                ],
                "metadata" => {
                  "pactSpecification" => { "version" => "4.0" }
                }
              }
            end

            let(:content) { Content.from_hash(pact_hash) }
            subject { Types.for(content).has_messages? }

            it "counts only interactions with type 'Asynchronous/Messages'" do
              expect(subject).to eq true
            end
          end

          context "when pact specification version is 3" do
            let(:pact_hash) do
              {
                "consumer" => { "name" => "Foo" },
                "provider" => { "name" => "Bar" },
                "messages" => [
                  {
                    "description" => "a message",
                    "contents" => { "foo" => "bar" }
                  },
                  {
                    "description" => "another message",
                    "contents" => { "baz" => "qux" }
                  }
                ],
                "metadata" => {
                  "pactSpecification" => { "version" => "3.0.0" }
                }
              }
            end

            let(:content) { Content.from_hash(pact_hash) }
            subject { Types.for(content).has_messages? }

            it "counts messages from the messages array" do
              expect(subject).to eq true
            end
          end

          context "when there are no messages" do
            let(:pact_hash) do
              {
                "consumer" => { "name" => "Foo" },
                "provider" => { "name" => "Bar" },
                "interactions" => [
                  {
                    "_id" => "http1",
                    "type" => "Synchronous/HTTP",
                    "description" => "an http request",
                    "request" => { "method" => "GET", "path" => "/foo" },
                    "response" => { "status" => 200 }
                  }
                ],
                "metadata" => {
                  "pactSpecification" => { "version" => "4.0" }
                }
              }
            end

            let(:content) { Content.from_hash(pact_hash) }
            subject { Types.for(content).has_messages? }

            it "returns false" do
              expect(subject).to eq false
            end
          end

          context "when messages array is missing in v3 pact" do
            let(:pact_hash) do
              {
                "consumer" => { "name" => "Foo" },
                "provider" => { "name" => "Bar" },
                "interactions" => [],
                "metadata" => {
                  "pactSpecification" => { "version" => "3.0.0" }
                }
              }
            end

            let(:content) { Content.from_hash(pact_hash) }
            subject { Types.for(content).has_messages? }

            it "returns false" do
              expect(subject).to eq false
            end
          end
        end
      end
    end
  end
end
