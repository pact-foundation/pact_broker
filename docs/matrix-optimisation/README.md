# Matrix query baselines

Tooling to capture a query-profile baseline (per-request query count, exact SQL,
and `EXPLAIN` plans) for the `/matrix` and `/can-i-deploy` endpoints, so query
cost can be compared before and after changes to the query engine.

The generated baseline files (`baseline-*.md`) are **git-ignored** — generate them
locally and diff two runs; they are not committed.

## Generate a baseline (Postgres)

Baselines are generated against **Postgres** (the production backend). Start a
throwaway Postgres with the dev compose file:

    docker compose -f docker-compose-dev-postgres.yml up -d postgres

The Postgres version is controlled by `POSTGRES_VERSION` (default `15`),
so a baseline can be captured against a specific major version:

    POSTGRES_VERSION=14 docker compose -f docker-compose-dev-postgres.yml up -d postgres

The `pg` driver lives in an optional bundle group, so it must be installed and
enabled explicitly — without `BUNDLE_WITH=pg` the run fails with
`LoadError: cannot load such file -- pg`:

    BUNDLE_WITH=pg bundle install

Point the suite at the database and run the generator:

    BUNDLE_WITH=pg \
      PACT_BROKER_TEST_DATABASE_URL="postgres://postgres:postgres@localhost:5432/postgres" \
      bundle exec rspec spec/benchmarks/matrix_baseline_spec.rb --tag matrix_baseline

This writes `docs/matrix-optimisation/baseline-postgres.md`. Tear the container down
with `docker compose -f docker-compose-dev-postgres.yml down -v` when done.

> Postgres 18 and later relocated the data directory, which is incompatible with
> the `/var/lib/postgresql/data` volume mount in `docker-compose-dev-postgres.yml`;
> the container exits on startup. Use a tag of `17` or lower until that mount is
> updated.

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
