require File.dirname(__FILE__) + '/config/boot'
require 'pact_broker/db'
require 'pact_broker/api'
require 'pact_broker/resources/pact'


use Rack::Static, root: 'public', urls: ['/favicon.ico']

run Rack::URLMap.new(
  '/' => PactBroker::API
)
