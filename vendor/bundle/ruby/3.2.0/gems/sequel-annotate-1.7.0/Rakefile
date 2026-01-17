require "rake"
require "rake/clean"

CLEAN.include ["sequel-annotate-*.gem", "rdoc"]

desc "Build sequel-annotate gem"
task :package=>[:clean] do |p|
  sh %{#{FileUtils::RUBY} -S gem build sequel-annotate.gemspec}
end

### Specs

desc "Run specs"
task :spec do
  sh "#{FileUtils::RUBY} -I lib spec/sequel-annotate_spec.rb"
end

task :default => :spec

desc "Run specs in CI"
task :spec_ci do
  ENV['SEQUEL_ANNOTATE_SPEC_CI'] = '1'
  if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
    ENV['SEQUEL_ANNOTATE_SPEC_POSTGRES_URL'] = "jdbc:postgresql://localhost/?user=postgres"
  else
    ENV['SEQUEL_ANNOTATE_SPEC_POSTGRES_URL'] = "postgres://localhost/?user=postgres"
  end
  Rake::Task['spec'].invoke
end

### RDoc

RDOC_DEFAULT_OPTS = ["--quiet", "--line-numbers", "--inline-source", '--title', 'sequel-annotate: Annotate Sequel models with schema information']

begin
  gem 'rdoc'
  gem 'hanna-nouveau'
  RDOC_DEFAULT_OPTS.concat(['-f', 'hanna'])
rescue Gem::LoadError
end

RDOC_OPTS = RDOC_DEFAULT_OPTS + ['--main', 'README.rdoc']

require "rdoc/task"
RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.options += RDOC_OPTS
  rdoc.rdoc_files.add %w"README.rdoc CHANGELOG MIT-LICENSE lib/**/*.rb"
end
