require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |task|
  # task.pattern = 'spec/**/*_spec.rb'
  task.pattern = 'spec/migrations/23_pact_versions_spec.rb'
end
