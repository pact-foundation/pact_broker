require "rspec/core"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new("spec:focus") do |task|
  task.rspec_opts = "--tag @focus"
end

RSpec::Core::RakeTask.new("spec:quick") do |task|
  task.rspec_opts = "--tag ~@no_db_clean --tag ~@migration --format progress"
end

RSpec::Core::RakeTask.new("regression") do |task|
  task.pattern = "regression/**{,/*/**}/*_spec.rb"
  task.rspec_opts = "--require ./regression/regression_helper.rb"
end

RSpec::Core::RakeTask.new("spec:slow") do |task|
  task.rspec_opts = "--tag @no_db_clean --tag @migration  --format progress"
end

task :set_simplecov_command_to_spec_quick do
  ENV["SIMPLECOV_COMMAND_NAME"] = "spec:quick"
end

task :set_simplecov_command_to_spec_slow do
  ENV["SIMPLECOV_COMMAND_NAME"] = "spec:slow"
end

task :enable_oas_coverage_check do
  ENV["OAS_COVERAGE_CHECK_ENABLED"] = "true"
end

task :disable_oas_coverage_check do
  ENV["OAS_COVERAGE_CHECK_ENABLED"] = nil
end

task "spec:quick" => ["set_simplecov_command_to_spec_quick", "enable_oas_coverage_check"]
task "spec:slow" => ["set_simplecov_command_to_spec_slow", "disable_oas_coverage_check"]
task :spec => ["spec:quick", "spec:slow"]

