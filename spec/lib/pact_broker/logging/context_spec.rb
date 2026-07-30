require "pact_broker/logging/context"
require "semantic_logger"

module PactBroker
  module Logging
    describe Context do
      before do
        Context.reset
      end

      after do
        Context.reset
      end

      def log_entry(message: "a message", payload: nil, named_tags: {}, level: :info)
        log = SemanticLogger::Log.new("Test", level)
        log.message = message
        log.payload = payload
        log.named_tags = named_tags
        log
      end

      describe ".register_provider" do
        it "accepts an object responding to call" do
          provider = -> { { a: 1 } }
          expect(Context.register_provider(:a, provider)).to eq provider
          expect(Context.provider_names).to eq [:a]
        end

        it "accepts a block" do
          Context.register_provider(:a) { { a: 1 } }
          expect(Context.provider_names).to eq [:a]
        end

        it "rejects something that cannot be called" do
          expect { Context.register_provider(:a, "not callable") }.to raise_error(ArgumentError, /#call/)
        end

        it "replaces a provider registered under the same name" do
          Context.register_provider(:a) { { value: "first" } }
          Context.register_provider(:a) { { value: "second" } }

          log = log_entry
          Context.call(log)

          expect(Context.provider_names).to eq [:a]
          expect(log.named_tags[:value]).to eq "second"
        end
      end

      describe ".deregister_provider" do
        it "removes the provider" do
          Context.register_provider(:a) { { a: 1 } }
          Context.deregister_provider(:a)

          log = log_entry
          Context.call(log)

          expect(log.named_tags).to eq({})
        end
      end

      describe ".call" do
        it "merges tags from all providers" do
          Context.register_provider(:a) { { a: 1 } }
          Context.register_provider(:b) { { b: 2 } }

          log = log_entry
          Context.call(log)

          expect(log.named_tags).to eq(a: 1, b: 2)
        end

        it "lets a later provider win a collision between providers" do
          Context.register_provider(:a) { { shared: "first" } }
          Context.register_provider(:b) { { shared: "second" } }

          log = log_entry
          Context.call(log)

          expect(log.named_tags[:shared]).to eq "second"
        end

        it "lets existing named tags win over a provider" do
          Context.register_provider(:a) { { request_id: "from-provider" } }

          log = log_entry(named_tags: { request_id: "from-tagged" })
          Context.call(log)

          expect(log.named_tags[:request_id]).to eq "from-tagged"
        end

        it "ignores a provider that returns nil" do
          Context.register_provider(:a) { nil }
          Context.register_provider(:b) { { b: 2 } }

          log = log_entry
          Context.call(log)

          expect(log.named_tags).to eq(b: 2)
        end

        it "handles a log entry whose named_tags are nil" do
          Context.register_provider(:a) { { a: 1 } }

          log = log_entry
          log.named_tags = nil

          expect { Context.call(log) }.to_not raise_error
          expect(log.named_tags).to eq(a: 1)
        end

        it "sanitises the payload" do
          log = log_entry(payload: { thing: Object.new })
          Context.call(log)

          expect(log.payload[:thing]).to be_a String
        end

        it "sanitises the message" do
          log = log_entry(message: "abc\xFFdef".dup.force_encoding("UTF-8"))
          Context.call(log)

          expect(log.message.valid_encoding?).to be true
        end

        def deep_payload
          { l1: { l2: { l3: { l4: { l5: { l6: "leaf" } } } } } }
        end

        it "truncates a deep payload at MAX_DEPTH when logged at info" do
          log = log_entry(payload: deep_payload, level: :info)
          Context.call(log)

          expect(log.payload[:l1][:l2][:l3][:l4]).to eq PayloadSanitizer::DEPTH_EXCEEDED
        end

        it "lets a deep payload survive to DEBUG_MAX_DEPTH when logged at debug" do
          log = log_entry(payload: deep_payload, level: :debug)
          Context.call(log)

          expect(log.payload[:l1][:l2][:l3][:l4][:l5][:l6]).to eq "leaf"
        end

        it "lets a deep payload survive to DEBUG_MAX_DEPTH when logged at trace" do
          log = log_entry(payload: deep_payload, level: :trace)
          Context.call(log)

          expect(log.payload[:l1][:l2][:l3][:l4][:l5][:l6]).to eq "leaf"
        end

        it "leaves a non-Hash payload alone, so exception payloads are not mangled" do
          exception = StandardError.new("boom")
          log = log_entry(payload: exception)

          Context.call(log)

          expect(log.payload).to be exception
        end

        context "when a provider raises" do
          before do
            Context.register_provider(:exploding) { raise "provider is broken" }
            Context.register_provider(:working) { { works: true } }
          end

          it "still applies the other providers" do
            log = log_entry
            allow($stderr).to receive(:puts)

            Context.call(log)

            expect(log.named_tags).to eq(works: true)
          end

          it "warns on stderr rather than logging, because logging here would recurse" do
            expect($stderr).to receive(:puts).with(/exploding/).once

            Context.call(log_entry)
          end

          it "warns only once, no matter how many entries are logged" do
            expect($stderr).to receive(:puts).with(/exploding/).once

            5.times { Context.call(log_entry) }
          end
        end
      end
    end
  end
end
