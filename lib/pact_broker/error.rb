module PactBroker
  class Error < StandardError; end
  class TestError < StandardError; end
  class ConfigurationError < PactBroker::Error; end
end
