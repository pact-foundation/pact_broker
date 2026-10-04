require "pact_broker/logging/setup"
require "pact_broker/config/runtime_configuration"
require "rack/pact_broker/request_context"
require "stringio"

describe "request correlation in log output" do
  let(:output) { StringIO.new }
  let(:app) do
    Rack::PactBroker::RequestContext.new(
      lambda do | _env |
        SemanticLogger["Test"].warn("something happened")
        [200, {}, ["ok"]]
      end
    )
  end

  def log_output_for(formatter)
    original_level = SemanticLogger.default_level
    SemanticLogger.default_level = :warn
    appender = SemanticLogger.add_appender(io: output, formatter: formatter, level: :warn)
    SemanticLogger.on_log(PactBroker::Logging::Context)
    app.call({})
    SemanticLogger.flush
    output.string
  ensure
    SemanticLogger.remove_appender(appender) if appender
    SemanticLogger.default_level = original_level
  end

  it "includes the request id in JSON output" do
    result = log_output_for(:json)

    # Verified shape of SemanticLogger 5.0's :json formatter output:
    # {"host":...,"application":...,"timestamp":...,"level":"warn",
    #  "named_tags":{"request_id":"..."},"name":...,"message":...}
    entry = JSON.parse(result.lines.last)
    expect(entry["named_tags"]["request_id"]).to match(/\A[0-9a-f]{32}\z/)
  end

  it "includes the request id in human readable output" do
    result = log_output_for(:default)

    expect(result).to match(/request_id: [0-9a-f]{32}/)
  end
end
