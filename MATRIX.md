# The Matrix

The Matrix is the dataset that is created when all the pacts are joined to all the verifications in the database, and it shows every consumer and provider version that have been tested against each other. The Matrix can be queried in may ways to find out whether particular versions are compatible with each other.

## Querying the matrix

The matix is queried using objects called "selectors". Selectors specify at minimum, the name of the pacticipant, and usually, a particular version, or range of versions, using any of version number, branch, environment or tag.

For example.



## can-i-deploy

The can-i-deploy query is a specific permutation of the matrix query that answers the question "can I deploy this application version(s) to a particular environment".

A matrix query is a can-i-deploy query if all of the following are true:

* The specified selectors each represent a single pacticipant version (because you can only deploy one version of an application at a time - it doesn't make sense to say "can I deploy every version of Foo from the main branch at once").
* There are either multiple specified selectors OR there is a single specified selector and a "target" (that is, `--to TAG` or `--to-environment` or `--latest`)

## can-i-merge

The can-i-merge query is the same as can-i-deploy, except the "target" is "the main branches" of the integrated applications rather than "the versions of the integrated applications that are deployed to a particular environment".

## Terminology

### Selectors

#### Selector classes

* `Unresolved selectors` - `PactBroker::Matrix::UnresolvedSelector` the class of the specified and ignore selectors, as they are created directly from the HTTP query. At this point, they are "unresolved" in that we do not know the IDs of the pacticipants/versions that they represent, and whether or not they even exist.

* `Resolved selectors` - `PactBroker::Matrix::ResolvedSelector` the class of the object created for each selector, after its pacticipant and version IDs have been identified. If a selector represents multiple pacticipant versions (eg `{ branch: "main" }`) then one `ResolvedSelector` object will be returned for each pacticipant version found. The resolved selector keeps a reference to its original unresolved selector, as well as the pacticipant ID and the version ID. If the version or pacticipant specified does not actually exist, then a resolved selector is returned that indicates this.

#### Selector collections

* `Specified selectors` - the collection of objects that describe the application version(s) specified explicitly in the matrix query. eg. in `can-i-deploy --pacticipant Foo --version 1` the specified selector is `PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1")`. There may be multiple specified selectors, for example, in the Matrix page for an integration Foo/Bar, the specified selectors would be `[ UnresolvedSelector.new(pacticipant_name: "Foo"), UnresolvedSelector.new(pacticipant_name: "Bar")]`. The selectors may use various combinations of pacticipant name, version number, branch, tag or environment to identify the pacticipant versions.

* `Ignore selectors` - the collection of objects that describe the applications (or application versions) to ignore, if there are any missing or failed verifications between the versions for the specified selectors and the ignore selectors. eg. If we know that provider Dog is not ready and the verifications are failing, but the integration is feature toggled off in the Foo code, we would use the command `can-i-deploy --pacticipant Foo --version 1 --to-environment production --ignore Dog` to allow `can-i-deploy` to pass. An ignore selector can have a version number, but it's more common to just provide the name.

* `Inferred selectors` - the collection of objects that describe the application versions(s) that already exist in the target environment/with the target tag/on the target branches. These are identified during the matrix query when the `can-i-deploy` query has a `--to TAG`/`--to-environment`/`--with-main-branches` option specified, and they allow us to find the full set of matrix rows that tell us whether or the application version we're about to deploy is compatible with its integrated applications. For example, given Foo v1 is a consumer of Bar, and Bar v8 is in production, and the `can-i-deploy` command is `can-i-deploy --pacticipant Foo --version 1 --to-environment production`, then an inferred unresolved selector is created for Bar in the production environment (`UnresolvedSelector.new(pacticipant_name: "Bar", environment_name: "production")`) which is then resolved to Bar v8.

#### Notes on selector classes/collections

Specified, ignore, and inferred selectors all start life as `UnresolvedSelector` objects, which then get resolved into `ResolvedSelector` objects.


## How the matrix query works

1. Given that Foo v1 is a consumer of Bar, and Bar v8 is currently in production, take the pact-broker CLI command `can-i-deploy --pacticipant Foo --version 1 --to-environment production --ignore Dog`

1. Turn that into a query string and make a request to the `/matrix` endpoint.

1. Parse the HTTP query into the specified selectors, the ignore selectors and options.

  * specified selectors - `PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1")`
  * ignore selectors - `PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "Dog")`
  * options: `{ to_environment: "production" }`

1. Validate the selectors.

  * Ensure conflicting fields are not used.
  * Return an error if any of the pacticipants in the specified selectors or the environment do not exist.
  * Do not check for the existance of version numbers or tags, or pacticipants in the ignore selectors.

1. "Resolve" the ignore selectors (find the pacticipant and version IDs for the selectors).

1. "Resolve" the specified selectors, passing in the ignore selectors to identify whether or not the resolved selector should be "ignored".

1. Identify the integrations that the versions in the specified selectors are involved in.

  * Identify the providers of the consumers: for the versions of each specified selector, find any pacts created for that version. If any exist, that means
    the provider for each pact MUST be deployed to the target environment, and the deployed version must have a successful verification with the specified consumer version for the consumer to be safe to deploy. The providers must be identified for the specific consumer *version* of the selector, not just *consumer*, as different versions of a consumer may have different providers as integrations are created and removed over time. This is why we cannot just query the integrations table.

    Represent the integration by creating a `PactBroker::Matrix::Integration` object for each consumer/provider pair, and mark it as `required: true`.

  * Identify the consumers of the providers: for the pacticipant of each specified selector, find any integrations in the integrations table where
    the specified pacticipant is the provider. Because specific provider versions don't have a dependency on any specific consumer versions being already present in an environment, we do not need to run this query at the pacticipant version level - we can just check the presence of any consumers at the integration level.

    Represent the integration by creating a `PactBroker::Matrix::Integration` object for each consumer/provider pair, and mark it as `required: false`.

1. Identify the inferred unresolved selectors (the selectors for the pacticipant versions that are already in the target scope)

  * Collect all the pacticipant names from the integrations identified in the previous step. For every pacticipant name that does NOT already have a specified selector, create a new unresolved "inferred" selector for that pacticipant, and set the version selection attributes to be the target scope from the original `can-i-deploy` query. eg. Given we have identifed the required `Integration` for consumer Foo and provider Bar, and we are determining if we can deploy Foo to production, create an unresolved selector for Bar in the production environment (`UnresolvedSelector.new(pacticipant_name: "Bar", environment_name: "production"`).

1. "Resolve" the inferred selectors (find the pacticipant and version IDs).

1. Add the specified and inferred resolved selectors together to make the final collection of selectors that will be used to query the matrix.

1. Peform the matrix query.

  * When there are 2 or more total resolved selectors (the usual usecase):

    * Create a collection of all the pacticipants in the selectors (let's call it `all_pacticipants_in_selectors`).

    * Create the pact/consumer version dataset

      * For each selector, find the pact publications where the consumer version is one of the versions described by the selector, and the provider is one of `all_pacticipants_in_selectors`.

    * Create the verification/provider version dataset.

      * For each selector, find the verifications where the provider version is one of the versions described by the selector, and the consumer is one of `all_pacticipants_in_selectors`.

    * Join the pact/consumer verison dataset to the verification/provider version dataset.

      * The two datasets are joined on the `pact_version_id` - this is the ID of the unique pact content that every pact publication and provider verification has a reference to. A left outer join is used, so that if there is a pact that doesn't have a verification, a row is present for the pact, with empty provider version columns. This allows us to identify that there is a missing verification.


  * When there is only 1 total resolved selector: this is an unusual usecase, and cannot be done via the UI or the CLI, so I'm not going to spend time documenting it. Just know it is supported and theoretically possible.



