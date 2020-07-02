source 'https://rubygems.org'

gemspec

gem 'simplecov', :require => false, :group => :test

group :development do
  gem 'pry-byebug'
end

group :test do
  gem 'pact', '~>1.14'
  gem 'rspec-pact-matchers', '~>0.1'
  gem 'bundler-audit', '~>0.4'
  gem 'sqlite3', '~>1.3'
  gem 'rake', '~>12.3.3'
  gem 'fakefs', '~>0.4'
  gem 'webmock', '~>2.3'
  gem 'rspec', '~>3.0'
  gem 'rspec-its', '~>1.2'
  gem 'database_cleaner', '~>1.8', '>= 1.8.1'
  gem 'conventional-changelog', '~>1.3'
  gem 'bump', '~> 0.5'
  gem 'timecop', '~> 0.9'
  gem 'sequel-annotate', '~>1.3'
  gem 'faraday', '~>0.15'
  gem 'docker-api', '~>1.34'
end

if ENV['INSTALL_MYSQL'] == "true"
  gem 'mysql2', '~>0.5'
end

if ENV['INSTALL_PG'] == 'true'
  gem 'pg', '~>1.2'
end
