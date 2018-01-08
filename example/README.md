# Run Pact Broker example

Clone project

```bash
git clone https://github.com/pact-foundation/pact_broker
```

Change directory to `example`

```bash
cd pact_broker/example
```

## Run with sqlite database

Install dependencies

```bash
bundle install
```

Run Pact Broker

```bash
bundle exec rackup
```

## Run with postgres database

Uncomment `gem 'pg'` in the [Gemfile](Gemfile)

Comment out `gem 'sqlite3'` in the [Gemfile](Gemfile)

Comment out the line with `DATABASE_CREDENTIALS = {adapter: "sqlite"...` in the [config.ru](config.ru#L9).

Uncomment the line with `DATABASE_CREDENTIALS = {adapter: "postgres"...`. in the [config.ru](config.ru#L17).

Set up postgres database

```bash
psql postgres -c "CREATE DATABASE pact_broker;"
psql postgres -c "CREATE ROLE pact_broker WITH LOGIN PASSWORD 'pact_broker';"
psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE pact_broker TO pact_broker;"
```

Install dependencies

```bash
bundle install
```

Run Pact Broker

```bash
bundle exec rackup
```

If you need an example data run following command

```bash
psql pact_broker < example_data.sql
```

Now Pact Broker can be access locally at [http://localhost:9292](http://localhost:9292).
