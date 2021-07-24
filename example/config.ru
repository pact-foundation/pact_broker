require "pact_broker"

ENV["RACK_ENV"] ||= "production"
ENV["TZ"] = "Australia/Melbourne" # Set the timezone you want your dates to appear in

app = PactBroker::App.new do | config |
  config.log_configuration
end

run app
