# Run Pact Broker example

It is recommended to use the [Docker Pact Broker image][docker-pact-broker] for production use.

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
bundle exec puma
```

Now Pact Broker can be access locally at [http://localhost:9292](http://localhost:9292).

## Run with postgres database

Create a postgres database

```bash
psql postgres -c "CREATE DATABASE pact_broker;"
psql postgres -c "CREATE ROLE pact_broker WITH LOGIN PASSWORD 'pact_broker';"
psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE pact_broker TO pact_broker;"
```

Uncomment `gem 'pg'` in the [Gemfile](Gemfile)

Comment out `gem 'sqlite3'` in the [Gemfile](Gemfile)

Replace the `database_url` in `config/pact_broker.yml` with `postgres://pact_broker:pact_broker@<YOUR_DB_HOST>/pact_broker`

Install dependencies

```bash
bundle install
```

Run Pact Broker

```bash
bundle exec puma
```

Now Pact Broker can be access locally at [http://localhost:9292](http://localhost:9292).

[docker-pact-broker]: https://github.com/pact-foundation/pact-broker-docker
[pact-broker-dir]: https://github.com/pact-foundation/pact-broker-docker/tree/master/pact_broker
