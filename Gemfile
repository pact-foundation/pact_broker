source 'https://rubygems.org'

gemspec

gem 'simplecov', :require => false, :group => :test

group :development do
  gem 'pry-byebug'
end

if ENV['INSTALL_MYSQL'] == "true"
  gem 'mysql2', '~>0.5'
end

if ENV['INSTALL_PG'] == 'true'
  gem 'pg', '~>1.2'
end
