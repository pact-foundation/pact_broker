require File.dirname(__FILE__) + '/config/boot'
require 'db'
require 'pact_broker/api'
require 'rack/hal_browser'
require 'pact_broker/ui/controllers/relationships'


use Rack::Static, :urls => ["/stylesheets", "/css", "/fonts", "/js", "/javascripts"], :root => "public"
use Rack::HalBrowser::Redirect, :exclude => ['/diagnostic', '/trace','/index']

run Rack::URLMap.new(
  '/ui/relationships' => PactBroker::UI::Controllers::Relationships,
  '/network-graph' => Rack::File.new("#{File.dirname(__FILE__)}/public/Network Graph REA.html"),
  '/' => PactBroker::API,
)
