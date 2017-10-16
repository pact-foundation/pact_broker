# Upgrading from a previous version of the Pact Broker

## Pact Broker versions >= 2.1.0

Backwards compatibility tests will ensure that the latest version of the database will be compatible with a previous version of the code until v3.0.0 for the following endpoints:

* Tag version
* Publish pact
* Retrieve latest pact
* Retrieve latest pact for tag

This means that zero downtime rolling upgrades for architectures that use multiple web servers (eg. Amazon autoscaling groups) are supported between any two versions from 2.1.0.

When backwards-incompatible changes need to be made in the future, a zero downtime upgrade path will documented on this page.

## Pact Broker < 2.1.0

The upgrades between 1.18.0 and 2.1.0 contains database migrations that are NOT backwards compatible with previous versions of the code. It is recommended to run a single instance of the broker while performing an upgrade that traverses these versions.
