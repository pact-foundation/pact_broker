require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec:broken') do |task|
  task.rspec_opts = '--tag @broken_on_mysql'
end

RSpec::Core::RakeTask.new('spec:quick') do |task|
  task.rspec_opts = '--tag ~@no_db_clean --tag ~@migration'
end

RSpec::Core::RakeTask.new('spec:slow') do |task|
  task.rspec_opts = '--tag @no_db_clean --tag @migration'
end

task :spec => ['spec:broken']
