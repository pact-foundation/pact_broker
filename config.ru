require "pact_broker"

ENV["TZ"] = "Australia/Melbourne"

app = PactBroker::App.new do | config |
  if config.log_stream == :file
    config.log_dir = File.expand_path("./log")
  else
    config.log_dir = nil # log to stdout instead of file
  end
  config.base_urls = ["http://localhost:9292"]
  config.database_url = "sqlite:////tmp/pact_broker_database.sqlite3"
end

run app
