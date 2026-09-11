
task :set_simplecov_command_to_pact_verify do
  ENV["SIMPLECOV_COMMAND_NAME"] = "pact:verify"
end

namespace :pact do
  task :prepare => ["db:set_test_env", "db:prepare:test", "set_simplecov_command_to_pact_verify",]
  task :verify => :prepare
  task "verify:at" => :prepare
  task "verify:dev" => :prepare
end

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new("pact:v2:verify") do |task|
  ENV["SIMPLECOV_COMMAND_NAME"] = "pact:v2:verify"
  task.pattern = "spec/pact/consumers/*_spec.rb"
  task.rspec_opts = ["-t pact"]
end
