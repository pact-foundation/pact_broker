require File.dirname(__FILE__) + '/config/boot'
require 'db'
require 'pact_broker/api'
require 'rack/hal_browser'

use Rack::HalBrowser::Redirect, :exclude => ['/diagnostic', '/trace']

run Rack::URLMap.new(
  '/' => PactBroker::API
)
