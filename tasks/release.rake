require 'conventional_changelog'

task :generate_changelog do
  require 'pact_broker/version'
  ConventionalChangelog::Generator.new.generate! version: "v#{PactBroker::VERSION}"
end
