require File.dirname(__FILE__) + '/config/boot'
require 'db'
require 'pact_broker/api'
require 'rack/hal_browser'


use Rack::Static, :urls => ["/stylesheets"], :root => "public"
use Rack::HalBrowser::Redirect, :exclude => ['/diagnostic', '/trace','/index','/force.csv']

run Rack::URLMap.new(
  '/index.html' => Rack::File.new("#{File.dirname(__FILE__)}/assets/index.html"),
  '/index2.html' => Rack::File.new("#{File.dirname(__FILE__)}/assets/index2.html"),
  '/force.csv' => Rack::File.new("#{File.dirname(__FILE__)}/assets/force.csv"),
  '/' => PactBroker::API
)
