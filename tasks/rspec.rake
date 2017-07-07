require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new('spec:quick') do |task|
  task.rspec_opts = '--tag ~@no_db_clean'
end
