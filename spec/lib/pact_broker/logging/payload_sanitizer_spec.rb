require "pact_broker/logging/payload_sanitizer"

module PactBroker
  module Logging
    describe PayloadSanitizer do
      describe ".call" do
        it "passes through JSON-safe scalars unchanged" do
          expect(PayloadSanitizer.call("abc")).to eq "abc"
          expect(PayloadSanitizer.call(:abc)).to eq :abc
          expect(PayloadSanitizer.call(42)).to eq 42
          expect(PayloadSanitizer.call(1.5)).to eq 1.5
          expect(PayloadSanitizer.call(true)).to eq true
          expect(PayloadSanitizer.call(false)).to eq false
          expect(PayloadSanitizer.call(nil)).to be nil
        end

        it "passes through a clean nested payload unchanged" do
          payload = { a: "one", b: [1, 2, { c: :three }] }
          expect(PayloadSanitizer.call(payload)).to eq payload
        end

        it "scrubs invalid UTF-8 byte sequences" do
          invalid = "abc\xFFdef".dup.force_encoding("UTF-8")
          expect(invalid.valid_encoding?).to be false

          result = PayloadSanitizer.call(invalid)

          expect(result.valid_encoding?).to be true
          expect(result).to eq "abc?def"
        end

        it "scrubs invalid UTF-8 nested inside a hash, including in keys" do
          invalid = "k\xFF".dup.force_encoding("UTF-8")

          result = PayloadSanitizer.call({ invalid => invalid })

          expect(result.keys.first.valid_encoding?).to be true
          expect(result.values.first.valid_encoding?).to be true
        end

        it "replaces an unserialisable object with a truncated inspect string" do
          object = Object.new

          result = PayloadSanitizer.call({ thing: object })

          expect(result[:thing]).to be_a String
          expect(result[:thing]).to include "Object"
        end

        it "truncates a very long inspect string" do
          long = Struct.new(:value).new("x" * 1000)

          result = PayloadSanitizer.call(long)

          expect(result.length).to be <= PayloadSanitizer::MAX_INSPECT_LENGTH + PayloadSanitizer::TRUNCATION_SUFFIX.length
          expect(result).to end_with PayloadSanitizer::TRUNCATION_SUFFIX
        end

        it "caps depth rather than recursing forever on a cyclic structure" do
          cyclic = {}
          cyclic[:self] = cyclic

          expect { PayloadSanitizer.call(cyclic) }.to_not raise_error

          result = PayloadSanitizer.call(cyclic)
          deepest = PayloadSanitizer::MAX_DEPTH.times.reduce(result) { |acc, _| acc.is_a?(Hash) ? acc[:self] : acc }
          expect(deepest).to eq PayloadSanitizer::DEPTH_EXCEEDED
        end

        it "caps depth on deeply nested arrays" do
          nested = [[[[[["deep"]]]]]]
          expect(PayloadSanitizer.call(nested).flatten.first).to eq PayloadSanitizer::DEPTH_EXCEEDED
        end

        it "returns a placeholder rather than raising when inspect itself raises" do
          exploding = Class.new do
            def inspect
              raise "no inspect for you"
            end
          end.new

          expect(PayloadSanitizer.call(exploding)).to include "uninspectable"
        end

        it "preserves Time values so formatters can format them" do
          time = Time.now
          expect(PayloadSanitizer.call(time)).to eq time
        end
      end

      describe "performance of the fast path" do
        it "does not allocate for a payload that is already safe" do
          payload = { pacticipant: "Foo", version: "1.2.3", count: 4 }
          PayloadSanitizer.call(payload) # warm up

          before = GC.stat(:total_allocated_objects)
          100.times { PayloadSanitizer.call(payload) }
          allocated = GC.stat(:total_allocated_objects) - before

          # A new hash per call plus a handful of internal objects is expected;
          # this guards against accidentally introducing string allocation per key.
          expect(allocated).to be < 100 * 20
        end
      end
    end
  end
end
