# Pact Broker

The Pact Broker provides a repository for pacts created using the pact gem.

## Usage

Create a new Ruby project, and include the pact_broker gem. You will need to create a connection using the Sequel gem to the database of your choice.



```ruby
# In config.ru

# Setup your Sequel connection
logger = Logger.new(File.join("./log"))
db_credentials = {host: "host", username: "username", password: "password", database: "database", adapter: "mysql2"}
# Use whatever sequel configs make sense for you, these are just what we use
con = Sequel.connect(db_credentials.merge(:logger => logger, :pool_class => Sequel::ThreadedConnectionPool))
con.extension(:connection_validator)
con.pool.connection_validation_timeout = -1

# Require the Pact Broker API
require 'pact_broker/api'

# Mount it

run Rack::URLMap.new(
  '/' => PactBroker::API
)
```

#TODO migrations
