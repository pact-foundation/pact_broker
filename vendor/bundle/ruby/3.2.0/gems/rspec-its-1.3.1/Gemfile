source 'https://rubygems.org'

# Specify your gem's dependencies in rspec-its.gemspec
gemspec

%w[rspec rspec-core rspec-expectations rspec-mocks rspec-support].each do |lib|
  branch = ENV.fetch('BRANCH','main')
  library_path = File.expand_path("../../#{lib}", __FILE__)

  if File.exist?(library_path) && !ENV['USE_GIT_REPOS']
    gem lib, :path => library_path
  elsif lib == 'rspec'
    gem 'rspec', :git => "https://github.com/rspec/rspec-metagem.git", :branch => branch
  else
    gem lib, :git => "https://github.com/rspec/#{lib}.git", :branch => branch
  end
end

if RUBY_VERSION < '2.2.0' && !!(RbConfig::CONFIG['host_os'] =~ /cygwin|mswin|mingw|bccwin|wince|emx/)
  gem 'ffi', '< 1.10'
elsif RUBY_VERSION < '2.4.0' && !!(RbConfig::CONFIG['host_os'] =~ /cygwin|mswin|mingw|bccwin|wince|emx/)
  gem 'ffi', '< 1.15'
elsif RUBY_VERSION < '2.0'
  gem 'ffi', '< 1.9.19' # ffi dropped Ruby 1.8 support in 1.9.19
elsif RUBY_VERSION < '2.3.0'
  gem 'ffi', '~> 1.12.0'
else
  gem 'ffi', '~> 1.15.0'
end

# test coverage
# gem 'simplecov', :require => false

gem 'contracts', '< 0.16' if RUBY_VERSION < '1.9.0'

gem 'coveralls', :require => false, :platform => :mri_20

eval File.read('Gemfile-custom') if File.exist?('Gemfile-custom')
