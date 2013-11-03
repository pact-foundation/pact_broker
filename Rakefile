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


FileList['lib/tasks/**/*.rake'].each { |task| load "#{Dir.pwd}/#{task}" }
FileList['tasks/**/*.rake'].each { |task| load "#{Dir.pwd}/#{task}" }

task :default => [:spec, 'pact:verify']

require File.join(File.dirname(__FILE__), 'config/boot')

