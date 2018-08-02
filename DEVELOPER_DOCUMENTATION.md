# Developer Documentation

## File structure

* Application code - [lib](lib)
  * List of API endpoints - [lib/pact_broker/api.rb](lib/pact_broker/api.rb)
  * API - [lib/pact_broker/api](lib/pact_broker/api)
    * HTTP Resources - [lib/pact_broker/api/resources](lib/pact_broker/api/resources) These handle the HTTP requests.
    * Decorators - [lib/pact_broker/api/decorators](lib/pact_broker/api/decorators) These render the response bodies.
    * Contracts - [lib/pact_broker/api/contracts](lib/pact_broker/api/contracts) These validate incoming API requests.
  * Domain - Domain classes were intially created in [lib/pact_broker/domain](lib/pact_broker/domain) but are now put in their own modules. The ones left here just haven't been migrated yet.
* Database migrations - [db/migrations](db/migrations)

* Tests - `spec`
  * Isolated tests (mostly) - `spec/lib`
  * Contract tests - `spec/service_consumers`
  * High level API functional tests - `spec/features`
  * Migration tests - `spec/migrations`

## Domain and database design

### Domain

Domain classes are found in `lib/pact_broker/domain`. Many of these classes are Sequel models, as the difference between the Sequel model and the functionality required for the domain logic is similar enough to share the class. Some classes separate the domain and database logic, as the concerns are too different. Where there is a separate database model, this will be kept in a module with the pluralized name of the model eg. `PactBroker::Webhooks`. Unfortunately, this sometimes makes it difficult to tell in the calling code whether you have a domain or a database model. I haven't worked out a clean way to handle this yet.

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

* `latest_pact_publications_by_consumer_versions` - This view has the same columns as `all_pact_publications`, but it only contains the latest revision of the pact for each provider/consumer/version. It maps to what a user would consider the "pact" resource ie. `/pacts/provider/Provider/consumer/Consumer/version/1.2.3`. Previous revisions are not currently exposed via the API.

 The `AllPactPublications` Sequel model in the code is what is used when querying data for displaying in a response, rather than the normalised separate PactPublication and PactVersion models.

* `latest_pact_publications` - This view has the same columns as `all_pact_publications`, but it only contains the latest revision of the pact for the latest consumer version for each consumer/provider pair. It is what a user would consider the "latest pact", and maps to the resource at `/pacts/provider/Provider/consumer/Consumer/latest`

* `latest_tagged_pact_publications` - This view has the same columns as `all_pact_publications`, plus a `tag_name` column. It is used to return the pact for the latest tagged version of a consumer.

* `latest_verifications` - The most recent verification for each pact version.

* `matrix` - The matrix of every pact publication and verification. Includes every pact revision (eg. publishing to the same consumer version twice, or using PATCH) and every verification (including 'overwritten' ones. eg. when the same provider build runs twice.)

* `latest_matrix_for_consumer_version_and_provider_version` - This view is a subset of, and has the same columns as, the `matrix`. It removes 'overwritten' pacts and verifications from the matrix (ie. only show latest pact revision for each consumer version and latest verification for each provider version)

### Materialized Views

We can't use proper materialized views because we have to support MySQL :|

So as a hacky solution, there are two tables which act as materialized views to speed up the performance of the matrix and index queries. These tables are updated after any resource is published with a `consumer_name`, `provider_name` or `pacticipant_name` in the URL (see lib/pact_broker/api/resources/base_resource.rb#finish_request).

* `materialized_matrix` table - is populated from the `matrix` view.

* `materialized_head_matrix` table - is populated from `head_matrix` view, and is based on `materialized_matrix`.

### Dependencies

```
materialized_head_matrix table (is populated from...)
  = head_matrix view
    -> latest_pact_publications
      -> latest_pact_publications_by_consumer_versions
        -> latest_pact_publication_ids_by_consumer_versions
        -> all_pact_publications
          -> versions, pacticipants, pact_publications, pact_versions
    -> latest_verifications
      -> latest_verification_numbers
      -> versions
    -> latest_tagged_pact_consumer_version_orders
    -> latest_pact_publications_by_consumer_versions
```

### Useful to know stuff

* The supported database types are Postgres (recommended), MySQL (sigh) and Sqlite (just for testing, not recommended for production). Check the travis.yml file for the supported database versions.
* Any migration that uses the "order" column has to be defined using the Sequel DSL rather than pure SQL, because the word "order" is a key word, and it has to be escaped correctly and differently on each database (Postgres, MySQL, Sqlite).
