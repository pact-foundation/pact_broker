# Developer Documentation

# Table of Contents

1. [Technology](#technology)
2. [File Structure](#file-structure)
3. [Domain and Database Design](#domain-and-database-design)
4. [Adding a Resource](#adding-a-resource)
5. [Writing Database Migrations](#writing-data-migrations)

## Technology

* [Ruby](https://www.ruby-lang.org/en/) - The application is written in Ruby
* [Rack](https://github.com/rack/rack) - This repo is a Rack application
* [Webmachine-ruby](https://github.com/webmachine/webmachine-ruby) - A toolkit for writing APIs
* [Sequel](https://github.com/jeremyevans/sequel) - Ruby Gem for writing Sequel to interface with the DB layer

## File structure

The back-end is a Rack application which uses Webmachine-ruby to create API endpoints and define how they can be used.

The UI in this repo is used for the OSS pact-broker.

### Application code - [lib](lib)

* The aggregated application (API, UI, middleware, HAL Browser, diagnostic endpoints etc)
  - [lib/pact_broker/app.rb](lib/pact_broker/app.rb)
* API - [lib/pact_broker/api](lib/pact_broker/api)
  * Routes - [lib/pact_broker/api.rb](lib/pact_broker/api.rb)
  * HTTP Resources - [lib/pact_broker/api/resources](lib/pact_broker/api/resources) These handle the HTTP
    requests.
  * Decorators - [lib/pact_broker/api/decorators](lib/pact_broker/api/decorators) These parse the request bodies
    and render the response bodies.
  * Contracts - [lib/pact_broker/api/contracts](lib/pact_broker/api/contracts) These validate incoming API
    requests.
* Domain - Domain classes were intially created in [lib/pact_broker/domain](lib/pact_broker/domain) but are now put
  in their own modules. The ones left here just haven't been migrated yet. The module name is the plural of the
  domain class name. eg `lib/pact_broker/widgets/widget.rb`.
* Services and Repositories - in the module with the name of their domain concept.
  eg `lib/pact_broker/widgets/service.rb` and `lib/pact_broker/widgets/repository.rb`
* Standalone "function as class" classes go into the module they relate to. This pattern is used when there is some
  significant stateless logic that we want to
* Database migrations - [db/migrations](db/migrations)
* Tests - `spec`
  * Isolated tests (mostly) - `spec/lib`
  * Contract tests - `spec/service_consumers`
  * High level API functional tests - `spec/features`
  * Migration tests - `spec/migrations`

### PactBroker UI

* UI - [lib/pact_broker/ui](lib/pact_broker/ui)
  * Routes - [lib/pact_broker/ui/app.rb](lib/pact_broker/ui/app.rb)
  * Controllers - [lib/pact_broker/ui/controllers](lib/pact_broker/ui/controllers) These handle the HTTP requests.
  * Views - [lib/pact_broker/ui/views](lib/pact_broker/ui/views) These render the view using HAML
  * View models - [lib/pact_broker/ui/view_models](lib/pact_broker/ui/view_models) These expose the domain model
    data in a way that is suited to rendering in a view.

## Domain and database design

### Domain

Domain classes are found in `lib/pact_broker/domain`. Many of these classes are Sequel models, as the difference between the Sequel model and the functionality required for the domain logic is similar enough to share the class. Some classes separate the domain and database logic, as the concerns are too different. Where there is a separate database model, this will be kept in a module with the pluralized name of the model eg. `PactBroker::Webhooks`. Unfortunately, this sometimes makes it difficult to tell in the calling code whether you have a domain or a database model. I haven't worked out a clean way to handle this yet.

### Domain terminology

* `pacticipant` - an application that participates in a pact. A very bad pun which I deeply regret.
* `pact` - this term is confusing and overloaded. It generally means a `pact publication` in the code.
* `pact publication` - the resource that gets created when a PUT request is sent to the Pact Broker to `/pacts/provider/PROVIDER/consumer/CONSUMER/version/VERSION`.
* `pact version` - the JSON contents of the pact publication. One pact version may belong to many pact publications. That is, if a pact publication with exactly the same contents is published twice, then a new
pact publication resource will be created with an incremented revision number, but it will reuse the existing pact version.
* `pacticipant version` - a resource that represents a version of the application
* `integration` - the relationship between a consumer and a provider
* `pseudo branch` - A time ordered list of pacts that are related to a particular tag. The most recent pact for each pseudo branch is a "head" pact.
* `matrix` - the table that shows the cartesian join of pact versions/verifications, and hence shows which consumer versions and provider versions have been tested together.

### Tables
* `pact_versions` - the JSON content of each UNIQUE pact document is stored in this table. The same content is likely to be published over and over again by the CI builds, so deduplicating the content saves us a lot of disk space. Once created, a row is never modified. Uniqueness is just done on string equality - no special pact logic. This means that pacts with randomly generated values or orders (most of pact-jvm pacts!) will get a new version record every time they publish.

* `pact_publications` - this table holds references to the:

    * `provider` (in the pacticipants table)
    * `consumer version` (in the versions table),
    * `pact content` (in the pact_version_contents table)
    * and a `revision number`

 A row exists for every `PUT` or `PATCH` request made to create or update a given pact resource. Once created, a row is never modified. When a pact resource (defined by the `provider`, `consumer` and `consumer version number`) is modified via HTTP, a new `pact_revision` row is created with an incremented `revision_number`. The `revision_number` begins at 1 for each new `consumer_version`.

* `versions` - this table consists of:

    * a reference to the `pacticipant` that owns the version (the `consumer`)
    * the version `number` (eg. 1.0.2)
    * the version `order` - an integer calculated by the code when the row is created that allows us to sort versions in the database without it needing to understand how to order semantic version strings. The versions are ordered within the context of their owning `pacticipant`.

 Currently only consumer versions are stored, as these are created when a pact resource is created. There is potential to create provider versions when we implement verifications.

* `pacticipants` - this table consists of:

    * a `name`

* `tags` - this table consists of:

    * a `name`
    * a reference to the `pacticipant version`

 Note that a `consumer version` is tagged, rather than a `pact_version`. This means that when a given version is marked as the "prod" one, all the pacts for that version are considered the "prod" pacts, rather than having to tag them individually.

### Views

* `all_pact_publications` - A denormalised view the one-to-one attributes of a `pact_publication`, including:

    * `provider name` and `provider id`
    * `consumer name` and `consumer id`
    * `consumer version number` and `consumer version order`
    * `revision_number`

* `latest_pact_publications_by_consumer_versions` - This view has the same columns as `all_pact_publications`, but it only contains the latest revision of the pact for each provider/consumer/version. It maps to what a user would consider the "pact" resource ie. `/pacts/provider/PROVIDER/consumer/CONSUMER/version/VERSION`. Previous revisions are not currently exposed via the API.

* `latest_pact_publications` - This view has the same columns as `all_pact_publications`, but it only contains the latest revision of the pact for the latest consumer version for each consumer/provider pair. It is what a user would consider the "latest pact", and maps to the resource at `/pacts/provider/PROVIDER/consumer/CONSUMER/latest`

* `latest_tagged_pact_publications` - This view has the same columns as `all_pact_publications`, plus a `tag_name` column. It is used to return the pact for the latest tagged version of a consumer.

* `latest_verifications_for_pact_versions` - The most recent verification for each pact version.

* `matrix` - The matrix of every pact publication and verification. Includes every pact revision (eg. publishing to the same consumer version twice, or using PATCH) and every verification (including 'overwritten' ones. eg. when the same provider build runs twice.)


### Database modeling approach

In the beginning, I made a lot of Sequel models based on views that pulled in the different tables of data together (eg denormalising consumer, provider, pact publication and pact version in to `all_pact_publications`). This made the Ruby code quite simple, but it was not very performant. As time has progressed, I have moved more and more of the "data joining" code into the Ruby to optimise the queries. That's why there are a lot of "aggregated data" views that are not being used by the code any more.

### Useful to know stuff

* The supported database types are Postgres (recommended), MySQL (but not officially) and Sqlite (just for testing, not recommended
  for production). Check the travis.yml file for the supported database versions.
* Any migration that uses the "order" column has to be defined using the Sequel DSL rather than pure SQL, because the
  word "order" is a key word, and it has to be escaped correctly and differently on each database (Postgres, MySQL,
  Sqlite).

## Adding a Resource

Adding a resource is how new API endpoints can be added using Webmachine. The resource accepts (or rejects) HTTP
requests (GET, POST,
etc) and returns a payload with the requested response body.

### How To:

1. Start by adding a new high level feature spec in  `spec/features` that executes the new endpoint.
   The Basic rule of thumb is to check the http status code, and do a light touch of assertions on the body. See other
   tests in this file for reference.


2. Create a new directory for the classes that relate to your new resource. eg For a "Foo" resource,
   create `lib/pact_broker/foos`


3. Create a new migration in `db/migrations` that creates the underlying database table. Include an `up` and `down`
   section


4. Create a new database model for the resource that extends from Sequel::Model. eg `lib/pact_broker/foos/foo.rb`


5. Create a decorator in `spec/lib/pact_broker/api/decorators/` that will map to and from the representation that will
   be used in the HTTP request and response.
  * Write a spec for the decorator.


6. Validation: Endpoints that have a request body or query params need to include validation. Validation is added via
   creating a `contract` which responds to a `call` method and returns errors. This should be used as part of
   the `malformed_request?` method. We use the dry-validation library where possible but are overdue a version upgrade.

7. Add the HTTP resource in `lib/pact_broker/api/resources/`. It should extend from `BaseResource` (itself an extension
   of Webmachine::Resource).
  * Write a spec for the resource, stubbing out the behaviour you expect from your service.

8. Add the route to `lib/pact_broker/api.rb`


9. Create a service that has the methods that you need for the resource. eg. `lib/pact_broker/foos/service.rb`
  * Add the new service to `lib/pact_broker/services.rb`
  * Write a spec for the service, stubbing out the behaviour you expect from your repository.


10. Create a repository eg. `lib/pact_broker/foos/repository.rb`.
  * Add the new repository to `lib/pact_broker/repositories.rb`.
  * Write a spec for the repository.


11. Go back and make the original feature spec pass.


12. If there are consumer Pact tests for this API add provider states as required.


13. Profit (optional).

## Writing Data migrations

The same database may be used by multiple application instances to support highly available set ups and no downtime
deployments. This can lead to the situation where the database migrations have been applied, but new data is written to
the database by old application code, which may lead to some columns not being populated. The mitigation to this problem
is to run the *data* migrations only each time an application instance starts up. This ensures that that any data
inserted into the database by a previous version of the application are migrated. This is done automatically in
the `PactBroker::App` class.

If you write a schema migration that then requires a data migration to populate or update any columns:

* Create a data migrations class in `lib/pact_broker/db/data_migrations`, copying the existing pattern.
* Add a call to the new class at the end of `lib/pact_broker/db/migrate_data.rb`
* Make sure you check for the existance of the required columns, because you don't know which version of the database
  might be running with this code.
* Add a null check (eg. `db[:my_table].where(my_column: nil).update(...)`) where appropriate to make sure that the data
  migration doesn't run more than once.
* Don't use any Sequel Models, as this will run before the model classes are loaded, and migrations should never depend
  on Models because models change as the schema migrations are applied.
* Create a migration file in `db/migrations` that calls the data migration (eg.
  like `db/migrations/20190603_migrate_webhook_headers.rb`)
