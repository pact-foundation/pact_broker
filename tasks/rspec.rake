require 'rspec/core'
require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

RSpec::Core::RakeTask.new(:spec => ['ci:setup:rspecdoc']) do |task|
  task.pattern = FileList['spec/**/*_spec.rb']
end

task :overwrite_rack_env do
  ENV['RACK_ENV'] = 'test'
  RACK_ENV = 'test'
end

task :spec => [:overwrite_rack_env, 'db:recreate']
