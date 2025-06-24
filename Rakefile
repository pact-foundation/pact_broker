# encoding: utf-8
require "bundler/gem_tasks"

require "rubygems"
require "bundler"
begin
  if ARGV.map{|arg| arg.include?("spec") }.any?
    Bundler.setup(:default, :development, :test)
  else
    Bundler.setup(:default, :development)
  end
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

FileList["lib/tasks/**/*.rake"].each { |task| load "#{Dir.pwd}/#{task}" }
FileList["tasks/**/*.rake"].each { |task| load "#{Dir.pwd}/#{task}" }

task :default => ["db:prepare:test", :boot, :spec, "pact:verify", "bundle:audit"]

task :ci => ["db:prepare:test", :boot, :spec]

task :boot do
  require File.join(File.dirname(__FILE__), "config/boot")
end
