require 'sequel'
database_config = {adapter: "sqlite", database: "pact_broker_database.sqlite3", :encoding => 'utf8'}
DB = Sequel.connect(database_config)
