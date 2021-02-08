require 'fileutils'
require 'logger'
require 'sequel'
require 'pact_broker'

FileUtils.mkdir_p('tmp') unless ENV['PACT_BROKER_DATABASE_URL']

DATABASE_URL = ENV['PACT_BROKER_DATABASE_URL'] || 'sqlite://tmp/pact_broker_database.sqlite3'
DB_OPTIONS = { encoding: 'utf8', sql_log_level: :debug }

ENV['TZ'] = 'Australia/Melbourne'

SemanticLogger.add_appender(io: $stderr)
SemanticLogger.default_level = :info

app = PactBroker::App.new do | config |
  # config.logger.level = ::Logger::INFO
  config.auto_migrate_db = true
  config.enable_public_badge_access = true
  config.order_versions_by_date = true
  config.allow_missing_migration_files = true
  config.base_equality_only_on_content_that_affects_verification_results = true
  config.badge_provider_mode = :redirect

  config.webhook_retry_schedule = [3, 3, 3]
  config.webhook_host_whitelist = [/.*/, "10.0.0.0/8"]
  config.webhook_scheme_whitelist = ['http', 'https']
  config.webhook_http_method_whitelist = ['GET', 'POST']
  config.webhook_http_code_whitelist = [200, 201, 202]
  #config.base_url = ENV['PACT_BROKER_BASE_URL']

  database_logger = PactBroker::DB::LogQuietener.new(config.logger)
  config.database_connection = Sequel.connect(DATABASE_URL, DB_OPTIONS.merge(logger: database_logger))
end

run app
