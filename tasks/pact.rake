require "rspec/core/rake_task"

RSpec::Core::RakeTask.new("pact:v2:verify") do |task|
  ENV["SIMPLECOV_COMMAND_NAME"] = "pact:v2:verify"
  task.pattern = "spec/pact/consumers/*_spec.rb"
  task.rspec_opts = ["-t pact"]
end

task "pact:verify" => "pact:v2:verify"
