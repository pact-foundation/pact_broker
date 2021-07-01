require "simplecov"

SimpleCov.minimum_coverage 90

if ENV["SIMPLECOV_COMMAND_NAME"]
  SimpleCov.command_name ENV["SIMPLECOV_COMMAND_NAME"]
  case ENV["SIMPLECOV_COMMAND_NAME"]
  when "spec:quick"
    SimpleCov.minimum_coverage 92
  when "spec:slow"
    SimpleCov.minimum_coverage 92
  when "pact:verify"
    SimpleCov.minimum_coverage 62
  end
end

SimpleCov.start do
  add_filter "/db/"
  add_filter "/example/"
  add_filter "/spec/"
  add_filter "/tasks/"
  add_filter "/script/"
end
