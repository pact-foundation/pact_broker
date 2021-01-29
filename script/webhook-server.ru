require 'rack/utils'
STDOUT.sync = true
puts "Starting webhook server"

run -> (env) {
  status = 200
  puts Rack::Utils.parse_nested_query(env['QUERY_STRING']) if env['QUERY_STRING'] && env['QUERY_STRING'] != ''
  puts env['rack.input'].read
  [status, {"Content-Type" => "text/plain"}, ["Webhook response.\n"]]
}
