require 'semantic_logger'
require 'pact_broker/logging/default_formatter'

FileUtils.mkdir_p("log")
SemanticLogger.default_level = :error
SemanticLogger.add_appender(file_name: "log/test.log", formatter: PactBroker::Logging::DefaultFormatter.new)
