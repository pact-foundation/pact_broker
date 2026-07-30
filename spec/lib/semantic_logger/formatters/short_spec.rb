require "semantic_logger/formatters/short"

module SemanticLogger
  module Formatters
    describe Short do
      let(:formatter) { Short.new }
      let(:logger) { double("logger") }

      def log_entry(named_tags)
        log = SemanticLogger::Log.new("Test", :info)
        log.message = "a message"
        log.named_tags = named_tags
        log
      end

      around do | example |
        original = Short.hidden_named_tags
        example.run
        Short.hidden_named_tags = original
      end

      it "defaults to hiding the git sha and request id, which are noise in local development" do
        expect(Short.hidden_named_tags).to eq [:pact_broker_git_sha, :request_id]
      end

      it "hides the configured named tags" do
        output = formatter.call(log_entry(request_id: "abc", branch: "main"), logger)

        expect(output).to_not include "abc"
        expect(output).to include "branch: main"
      end

      it "lets a consumer add to the hidden tags" do
        Short.hidden_named_tags += [:tenant_id]

        output = formatter.call(log_entry(tenant_id: "t1", branch: "main"), logger)

        expect(output).to_not include "t1"
        expect(output).to include "branch: main"
      end

      it "accepts a bare symbol rather than requiring an array" do
        Short.hidden_named_tags = :tenant_id

        expect(Short.hidden_named_tags).to eq [:tenant_id]

        output = formatter.call(log_entry(tenant_id: "t1", branch: "main"), logger)
        expect(output).to_not include "t1"
        expect(output).to include "branch: main"
      end

      it "omits the named tags section entirely when everything is hidden" do
        output = formatter.call(log_entry(request_id: "abc"), logger)

        expect(output).to_not include "{"
      end

      it "includes the message" do
        expect(formatter.call(log_entry({}), logger)).to include "a message"
      end
    end
  end
end
