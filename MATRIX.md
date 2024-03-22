# Interpreting the Matrix results

* If there is a row with a blank provider version, it's because the pact for that consumer version hasn't been verified by that provider (the result of a left outer join).
* If there is no row, it's because it has been verified, but not by the provider version you've specified. (Beth: don't think this is true any more because I fixed this.)

## The Matrix

The Matrix is the dataset that is created when all the pacts are joined to all the verifications in the database, and it shows every consumer and provider version that have been tested against each other. The matrix can be queried in may ways to find out whether particular versions are compatible with each other.

## can-i-deploy

The can-i-deploy query is a specific permutation of the matrix query that answers the question "can I deploy this application version(s) to a particular environment".

A matrix query is a can-i-deploy query if all of the following are true:

* The specified selectors each represent a single pacticipant version (because you can only deploy one version of an application at a time - it doesn't make sense to say "can I deploy every version of Foo from the main branch at once").
* There are either multiple specified selectors OR there is a single specified selector and a "target" (that is, `--to TAG` or `--to-environment` or `--latest`)

## can-i-merge

The can-i-merge query is the same as can-i-deploy, except the "target" is "the main branches" of the integrated applications rather than "the versions of the integrated applications that are deployed to a particular environment".

## Terminology

* `Specified selectors` - the collection of objects that describe the application version(s) specified explicitly in the matrix query. eg. in `can-i-deploy --pacticipant Foo --version 1` the specified selector is `PactBroker::Matrix::UnresolvedSelector.new(pacticipant_name: "Foo", pacticipant_version_number: "1")`. There may be multiple specified selectors, for example, in the Matrix page for an integration Foo/Bar, the specified selectors would be `[ UnresolvedSelector.new(pacticipant_name: "Foo"), UnresolvedSelector.new(pacticipant_name: "Bar")]`. The selectors may use various combinations of pacticipant name, version number, branch, tag or environment to identify the pacticipant versions.

* `Ignore selectors` - the collection of objects that describe the applications (or application versions) to ignore, if there are any missing or failed verifications between the versions for the specified selectors and the ignore selectors. eg. If we know that provider Dog is not ready and the verifications are failing, but the integration is feature toggled off in the Foo code, we would use the command `can-i-deploy --pacticipant Foo --version 1 --to-environment production --ignore Dog` to allow `can-i-deploy` to pass. An ignore selector can have a version number, but it's more common to just provide the name.

* `Unresolved selectors` - `PactBroker::Matrix::UnresolvedSelector` the class of the specified and ignore selectors, as they are created directly from the HTTP query. At this point, they are "unresolved" in that we do not know the IDs of the pacticipants/versions that they represent, and whether or not they even exist.

* `Resolved selectors` - `PactBroker::Matrix::ResolvedSelector` the class of the object created for each selector, after its pacticipant and version IDs have been identified. If a selector represents multiple pacticipant versions (eg `{ branch: "main" }`) then one `ResolvedSelector` object will be returned for each pacticipant version found. The resolved selector keeps a reference to its original unresolved selector, as well as the pacticipant ID and the version ID. If the version or pacticipant specified does not actually exist, then a resolved selector is returned that indicates this.


## How the matrix query works

1. Take the pact-broker CLI command `can-i-deploy --pacticipant Foo --version 1 --to-environment production --ignore Dog`
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
1. Identify the integrations that the versions in the specified selectors are involved in. This can go one of two ways.
  * TODO
