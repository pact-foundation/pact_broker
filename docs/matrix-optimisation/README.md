# Matrix query baselines

Tooling to capture a query-profile baseline (per-request query count, exact SQL,
and `EXPLAIN` plans) for the `/matrix` and `/can-i-deploy` endpoints, so query
cost can be compared before and after changes to the query engine.

The generated baseline files (`baseline-*.md`) are **git-ignored** — generate them
locally and diff two runs; they are not committed.

## Generate a baseline (Postgres)

Baselines are generated against **Postgres** (the production backend). Start a
throwaway Postgres in Docker:

    docker run --rm -d --name pact-broker-baseline-pg \
      -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=pact_broker_test \
      -p 5433:5432 postgres:15

Point the suite at it and run the generator:

    PACT_BROKER_TEST_DATABASE_URL="postgres://postgres:postgres@localhost:5433/pact_broker_test" \
      bundle exec rspec spec/benchmarks/matrix_baseline_spec.rb --tag matrix_baseline

This writes `docs/matrix-optimisation/baseline-postgres.md`. Tear the container down
with `docker rm -f pact-broker-baseline-pg` when done.

The generator is tagged `matrix_baseline` and excluded from the default test run;
it only executes when invoked with `--tag matrix_baseline`. Against a non-Postgres
database it skips with a message.

## What's captured

For each request shape (see `spec/support/matrix_baseline/shapes.rb`), the file
records, inside collapsible sections:

- the number of SQL statements the request issued (main query + eager loads);
- the exact SQL of each statement;
- its `EXPLAIN` plan.

## Comparing runs

Regenerate and diff two `baseline-postgres.md` files to compare:

- **query count** per shape;
- **plan shape** — sequential vs index scans, sorts, join types, UNION branch count;
- **estimated cost / actual rows / buffers** from `EXPLAIN (ANALYZE, BUFFERS)`.
