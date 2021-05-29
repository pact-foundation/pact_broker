source 'https://rubygems.org'

gemspec

gem 'rake', '~>12.3.3'
gem 'sqlite3', '~>1.3'
gem 'conventional-changelog', '~>1.3'
gem 'bump', '~> 0.5'

group :development do
  gem 'pry-byebug'
  gem 'rubocop', '~>1.1'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'sequel-annotate', '~>1.3'
end

group :test do
  gem 'simplecov', :require => false
  gem 'pact', '~>1.14'
  gem 'rspec-pact-matchers', '~>0.1'
  gem 'bundler-audit', '~>0.4'
  gem 'fakefs', '~>0.4'
  gem 'webmock', '~>3.9'
  gem 'rspec', '~>3.0'
  gem 'rspec-its', '~>1.2'
  gem 'database_cleaner', '~>1.8', '>= 1.8.1'
  gem 'timecop', '~> 0.9'
  gem 'faraday', '~>0.15'
  gem 'faraday_middleware', '~> 0.14'
  gem 'docker-api', '~>1.34'
  gem 'approvals', '>=0.0.24', '<1.0.0'
end

if ENV['INSTALL_MYSQL'] == "true"
  gem 'mysql2', '~>0.5'
end

if ENV['INSTALL_PG'] == 'true'
  gem 'pg', '~>1.2'
end

if ENV['X_PACT_DEVELOPMENT'] == 'true'
  gem 'pact-support', path: '../pact-support'
end
