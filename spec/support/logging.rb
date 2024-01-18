require "semantic_logger"
require "pact_broker/logging/default_formatter"

FileUtils.mkdir_p("log")
SemanticLogger.default_level = :error

if ENV["DEBUG"] == "true"
  SemanticLogger.default_level = :info
  SemanticLogger.add_appender(io: $stdout)
end

# Print out the request and response when DEBUG=true
RSpec.configure do | config |
  config.after(:each) do | example |
    if ENV["DEBUG"] == "true" && defined?(last_response)
      last_request.env["rack.input"]&.rewind
      puts "------------------------------------------------------------"
      puts "Request: #{last_request.request_method} #{last_request.path}\n\n"
      puts "Rack env:\n#{last_request.env}\n\n"
      puts "Request body:\n#{last_request.env["rack.input"]&.read}"

      puts "\n\n"
      puts "Response status: #{last_response.status}\n\n"
      puts "Response headers: #{last_response.headers}\n\n"
      puts "Response body:\n#{last_response.body}"
      puts "------------------------------------------------------------"
      puts ""
    end
  end
end
