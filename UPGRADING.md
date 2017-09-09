# Upgrading from a previous version of the Pact Broker

## Pact Broker versions >= 2.0.0

Backwards compatibility for database migrations in relation to the codebase will be supported according to semantic versioning (ie. any backwards incompatible changes will be done in major releases). This means that zero downtime deployments using rolling upgrades for setups with multiple HTTP servers sharing the same database are supported between any 2 versions within the same major release.

A migration path will be provided for major releases to allow zero downtime deployments, and will be documented here.

## Pact Broker < 2.0.0

The upgrade between 1.18.0 and 2.0.0 contains database migrations that are NOT backwards compatible. It is recommended to run a single instance of the broker while performing an upgrade that traverses these versions.
