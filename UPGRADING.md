# Upgrading from a previous version of the Pact Broker

## Pact Broker >= 3.0.0

The `pact-support` gem is no longer a dependency. Code loaded alongside the broker, such as a custom `config.ru` or a plugin, can no longer rely on `Pact::*` constants (`Pact::ConsumerContract`, `Pact::Matchers`, `Pact::Term`) being available. Add `pact-support` to your own Gemfile if you need them.

The pact diff endpoint (`/pacts/provider/{provider}/consumer/{consumer}/version/{version}/diff/previous-distinct` and its siblings) and the publish-conflict notice now return a standard unified diff with context lines and `@@` hunk headers, in place of the previous format that elided unchanged regions with `...`. Keys that exist only in the newer pact now appear in the diff; the previous format omitted them.

The HTML pact page now renders request and response content as stored in the pact. Three cases render differently from before: pacts written by pact-ruby v1 with inline `json_class` matcher objects show those objects instead of their example values; arrays governed by a `min` matcher show the stored example instead of `min` copies of its first element; and v3 hash-form queries show the hash instead of a `k=v` string.

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
