require "pact_broker"

ENV["TZ"] = "Australia/Melbourne"

app = PactBroker::App.new do | config |
  config.log_stream = :stdout
  config.base_urls = ["http://localhost:9292"]
  config.database_url = "sqlite:////tmp/pact_broker_database.sqlite3"
  config.log_configuration # do this last so the logger is configured correctly
end

run app
