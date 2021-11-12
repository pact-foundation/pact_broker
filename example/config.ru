require "pact_broker"

ENV["TZ"] = "Australia/Melbourne" # Set the timezone you want your dates to appear in

run PactBroker::App.new
