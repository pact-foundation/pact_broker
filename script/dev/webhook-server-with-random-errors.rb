require 'rack/utils'
require 'rack'

STDOUT.sync = true
puts "Starting webhook server which will return random errors"

app = -> (env) {
  status = [200, 500, 500, 500].sample
  puts Rack::Utils.parse_nested_query(env['QUERY_STRING']) if env['QUERY_STRING'] && env['QUERY_STRING'] != ''
  puts env['rack.input'].read
  [status, {"Content-Type" => "text/plain"}, ["Webhook response.\n"]].tap { |it| puts it }
}

Rack::Server.start(
 :app => app,
 :server => 'webrick',
 :Port => 9393
)