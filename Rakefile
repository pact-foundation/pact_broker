# encoding: utf-8

require 'bundler/gem_helper'
module Bundler
  class GemHelper
    def install
      desc "Build #{name}-#{version}.gem into the pkg directory"
      task 'build' do
        build_gem
      end

      desc "Build and install #{name}-#{version}.gem into system gems"
      task 'install' do
        install_gem
      end

      GemHelper.instance = self
    end
  end
end
Bundler::GemHelper.install_tasks

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

ENV['CI_REPORTS']="reports"

# Put tasks that should be available in production as well as dev/test (such as db:migrate) in libs/tasks/production
FileList['lib/tasks/production/**/*.rake'].each { |task| load task }

# Gems in development/test won't be loaded by Bundler in production, make sure we don't try to load a task that doesn't exist
if ENV['RACK_ENV'] != 'production'

  FileList['lib/tasks/**/*.rake'].exclude(%r{/production/}).each { |task| load task }
  require 'pact/tasks'

  task :default => [:spec, 'pact:verify']
end

require File.join(File.dirname(__FILE__), 'config/boot')


namespace :db do
  desc 'DB migrations'
  task :migrate do
    require 'sequel'
    require 'pact_broker/db'

    Sequel.extension :migration
    Sequel::Migrator.run(DB::PACT_BROKER_DB, "db/migrations")
  end
end
