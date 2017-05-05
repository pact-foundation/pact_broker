require 'fileutils'
require 'logger'
require 'sequel'
require 'pact_broker'
require 'pg'

app = PactBroker::App.new do | config |
  config.database_connection = Sequel.connect(ENV['DATABASE_URL'], adapter: "postgres", encoding: 'utf8')
  config.protect_with_basic_auth :all, {username: ENV['PACT_BROKER_USERNAME'], password: ENV['PACT_BROKER_PASSWORD']}
end

run app