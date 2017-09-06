count = 0
run -> (env) {
  count += 1
  status = (count % 3 == 0) ? 200 : 500
  puts "Received request"; [status, {}, ["Hello. This might be an error.\n"]]
}
