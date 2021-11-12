#!/usr/bin/env ruby
# Requires openssl to be installed on the machine

require "bundler/setup"
Bundler.require

require "uri"
require "securerandom"
require "logger"
require "sequel"

uri_string = ARGV[0]
database = ARGV[1]
raise "Usage: bundle exec #{__FILE__} URI SQLITE_DATABASE_PATH" unless uri_string && database

# Modify this hash with the configuration for your database
# For example, a postgres connection would look like:
# DATABASE_CREDENTIALS = { logger: Logger.new($stdout), adapter: "postgres", host: "HOST", username: "USERNAME", password: "PASSWORD", :encoding => 'utf8' }
DATABASE_CREDENTIALS = { logger: Logger.new($stdout), adapter: "sqlite", database: database, :encoding => "utf8" }

uri = URI(uri_string)

certificate_command = "openssl s_client -showcerts -servername #{uri.host} -connect #{uri.host}:#{uri.port} </dev/null 2>/dev/null | openssl x509 -outform PEM"
certificate_content = `#{certificate_command}`

puts "Downloaded certificate from #{uri.host}: #{certificate_content}"

certificate_hash = {
  uuid: SecureRandom.urlsafe_base64,
  description: "Self signed certificate for #{uri.host}",
  content: certificate_content,
  created_at: DateTime.now,
  updated_at: DateTime.now
}

Sequel.connect(DATABASE_CREDENTIALS) do | connection |
  connection[:certificates].insert(certificate_hash)
end

puts "Done"
