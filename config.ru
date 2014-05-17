require File.dirname(__FILE__) + '/config/boot'
require 'db'
require 'pact_broker/api'
require 'rack/hal_browser'
require 'pact_broker/ui/controllers/relationships'


use Rack::Static, :urls => ["/stylesheets", "/css", "/fonts", "/js", "/javascripts"], :root => "public"
use Rack::HalBrowser::Redirect, :exclude => ['/diagnostic', '/trace','/index','/force.csv']

run Rack::URLMap.new(
  '/ui/relationships' => PactBroker::UI::Controllers::Relationships,
  '/index.html' => Rack::File.new("#{File.dirname(__FILE__)}/assets/index.html"),
  '/index2.html' => Rack::File.new("#{File.dirname(__FILE__)}/assets/index2.html"),
  '/network-graph' => Rack::File.new("#{File.dirname(__FILE__)}/public/Network Graph REA.html"),
  '/force.csv' => Rack::File.new("#{File.dirname(__FILE__)}/assets/force.csv"),
  '/' => PactBroker::API,
)
