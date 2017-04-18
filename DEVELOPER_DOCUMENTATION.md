# Developer Documentation

## Domain and database design

### Tables
* `pact_version_contents` - the JSON content of each UNIQUE pact document is stored in this table. The same content is likely to be published over and over again by the CI builds, so deduplicating the content saves us a lot of disk space. Once created, a row is never modified.

* `pact_revisions` - this table holds references to the:

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

* `all_pact_revisions` - A denormalised view the one-to-one attributes of a `pact_revision`, including:

    * `provider name` and `provider id`
    * `consumer name` and `consumer id`
    * `consumer version number` and `consumer version order`
    * `revision_number`

* `all_pacts` - This view has the same columns as `all_pact_revisions`, but it only contains the latest (current) revision of the pact for each provider/consumer/version. It maps to what a user would consider the "pact" resource ie. `/pacts/provider/Provider/consumer/Consumer/version/1.2.3`

 The AllPacts Sequel model in the code is what is used when querying data for displaying in a response, rather than the normalised separate PactRevision and PactVersionContent models.

* `latest_pacts` - This view has the same columns as `all_pact_revisions`, but it only contains the latest revision of the pact for the latest consumer version for each consumer/provider pair. It is what a user would consider the "latest pact", and maps to the resource at `/pacts/provider/Provider/consumer/Consumer/latest`

* `latest_tagged_pacts` - This view has the same columns as `all_pact_revisions`, plus a `tag_name` column. It is used to return the pact for the latest tagged version of a consumer.
