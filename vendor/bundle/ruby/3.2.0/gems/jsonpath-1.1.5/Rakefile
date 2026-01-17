# frozen_string_literal: true

desc 'run rubocop'
task(:rubocop) do
  require 'rubocop'
  cli = RuboCop::CLI.new
  cli.run
end

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

require 'bundler'
Bundler::GemHelper.install_tasks

task :test do
  $LOAD_PATH << 'lib'
  Dir['./test/**/test_*.rb'].each { |test| require test }
end

task default: %i[test rubocop]
