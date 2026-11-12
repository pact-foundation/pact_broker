require "pact_broker/pacts/interactions/types"

module PactBroker
  module Pacts
    module Interactions
      describe Types do
        def http_interaction(id = "http1")
          {
            "_id" => id,
            "type" => "Synchronous/HTTP",
            "description" => "an http request",
            "request" => { "method" => "GET", "path" => "/foo" },
            "response" => { "status" => 200 }
          }
        end

        def async_message(id = "msg1")
          { "_id" => id, "type" => "Asynchronous/Messages", "description" => "a message", "contents" => { "foo" => "bar" } }
        end

        def sync_message(id = "sync1")
          {
            "_id" => id,
            "type" => "Synchronous/Messages",
            "description" => "a synchronous message",
            "request" => { "contents" => { "foo" => "bar" } },
            "response" => [{ "contents" => { "baz" => "qux" } }]
          }
        end

        def untyped_interaction(description)
          {
            "description" => description,
            "request" => { "method" => "GET", "path" => "/foo" },
            "response" => { "status" => 200 }
          }
        end

        def pact_with(version, body)
          hash = { "consumer" => { "name" => "Foo" }, "provider" => { "name" => "Bar" } }.merge(body)
          hash["metadata"] = { "pactSpecification" => { "version" => version } } if version
          Content.from_hash(hash)
        end

        # name => [content, has_messages?, has_http_interactions?]
        let(:fixtures) do
          {
            "a v2 pact with untyped interactions" => [
              pact_with("2.0.0", "interactions" => [untyped_interaction("one"), untyped_interaction("two")]), false, true
            ],
            "a v3 pact with untyped interactions" => [
              pact_with("3.0.0", "interactions" => [untyped_interaction("one")]), false, true
            ],
            "a v3 pact with messages only" => [
              pact_with("3.0.0", "messages" => [{ "description" => "a message", "contents" => { "foo" => "bar" } }]), true, false
            ],
            "a v4 pact with Synchronous/HTTP only" => [
              pact_with("4.0", "interactions" => [http_interaction]), false, true
            ],
            "a v4 pact with Asynchronous/Messages only" => [
              pact_with("4.0", "interactions" => [async_message]), true, false
            ],
            "a v4 pact with Synchronous/Messages only" => [
              pact_with("4.0", "interactions" => [sync_message]), true, false
            ],
            "a v4 pact with HTTP and both message types" => [
              pact_with("4.0", "interactions" => [async_message, http_interaction, sync_message]), true, true
            ],
            "a v4-shaped pact with Asynchronous/Messages and no spec version" => [
              pact_with(nil, "interactions" => [async_message]), true, false
            ],
            "a v4-shaped pact with Synchronous/Messages and no spec version" => [
              pact_with(nil, "interactions" => [sync_message]), true, false
            ],
            "a v3 pact with typed message interactions" => [
              pact_with("3.0.0", "interactions" => [async_message]), true, false
            ],
            "a v4 pact with a messages array" => [
              pact_with("4.0", "messages" => [{ "description" => "a message", "contents" => { "foo" => "bar" } }]), true, false
            ],
            "a v4 pact with an unknown interaction type" => [
              pact_with("4.0", "interactions" => [http_interaction.merge("type" => "Something/Else")]), false, true
            ],
            "a v4 pact with empty interactions" => [
              pact_with("4.0", "interactions" => []), false, false
            ],
            "a pact with neither interactions nor messages" => [
              pact_with("3.0.0", {}), false, false
            ]
          }
        end

        describe "#has_messages?" do
          it "classifies every fixture" do
            actual = fixtures.transform_values { |(content, _, _)| Types.for(content).has_messages? }
            expected = fixtures.transform_values { |(_, has_messages, _)| has_messages }
            expect(actual).to eq expected
          end
        end

        describe "#has_http_interactions?" do
          it "classifies every fixture" do
            actual = fixtures.transform_values { |(content, _, _)| Types.for(content).has_http_interactions? }
            expected = fixtures.transform_values { |(_, _, has_http)| has_http }
            expect(actual).to eq expected
          end
        end

        describe "#message_interactions and #http_interactions" do
          let(:content) do
            pact_with(
              "4.0",
              "interactions" => [async_message("a"), http_interaction("h"), "not a hash", sync_message("s")],
              "messages" => [{ "description" => "legacy" }, 1]
            )
          end

          subject(:types) { Types.for(content) }

          it "returns messages entries and typed message interactions" do
            expect(types.message_interactions.map { |i| i["_id"] || i["description"] }).to eq ["legacy", "a", "s"]
          end

          it "returns the interactions that are not typed messages" do
            expect(types.http_interactions.map { |i| i["_id"] }).to eq ["h"]
          end
        end
      end
    end
  end
end
