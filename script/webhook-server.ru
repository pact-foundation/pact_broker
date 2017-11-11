require 'rack/utils'

count = 0
run -> (env) {
  count += 1
  status = (count % 3 == 0) ? 200 : 500
  puts Rack::Utils.parse_nested_query(env['QUERY_STRING'])
  puts env['rack.input'].read
  [status, {}, ["Hello. This might be an error.\n"]]
}
