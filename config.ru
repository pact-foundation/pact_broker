require File.dirname(__FILE__) + '/config/boot'
require 'pact_broker/api'


use Rack::Static, root: 'public', urls: ['/favicon.ico']

run Rack::URLMap.new(
  '/' => PactBroker::API,
)
