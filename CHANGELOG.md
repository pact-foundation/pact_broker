<a name="v2.29.0"></a>
### v2.29.0 (2019-03-15)


#### Features

* **matrix**
  * improve reasons in response when pacticipant cannot be deployed	 ([e96544f6](/../../commit/e96544f6))
  * allow provider to be deployed to an environment without the consumer having to be deployed there already	 ([475a4010](/../../commit/475a4010))

* change webhook execution failure log to info	 ([7238bc49](/../../commit/7238bc49))
* remove db/pact_broker_database.sqlite3 so we don't have conflicts in fork	 ([f68fce8b](/../../commit/f68fce8b))
* change error logs to info logs	 ([700f6992](/../../commit/700f6992))
* lock dry-logic to version that works	 ([28769040](/../../commit/28769040))
* allow a custom UI to be configured	 ([23695b08](/../../commit/23695b08))


#### Bug Fixes

* gracefully handle race conditions when publishing a new revision of a pact	 ([012c54f0](/../../commit/012c54f0))


<a name="v2.28.0"></a>
### v2.28.0 (2019-01-15)


#### Features

* enable file list in gemspec to work without git	 ([6dd27e26](/../../commit/6dd27e26))
* allow the database connection to be configured for async jobs	 ([6a745d4b](/../../commit/6a745d4b))
* add error reference to API error response and ensure potentially sensitive details from the exception message are not exposed	 ([e7bb4a01](/../../commit/e7bb4a01))


#### Bug Fixes

* show consumer/provider/global webhooks in webhook column on index page	 ([35f8bfc1](/../../commit/35f8bfc1))


<a name="v2.27.6"></a>
### v2.27.6 (2018-11-23)


#### Bug Fixes

* URL encode consumer version number in pact URL	 ([b58f4fbf](/../../commit/b58f4fbf))


<a name="v2.27.5"></a>
### v2.27.5 (2018-11-15)


#### Bug Fixes

* handle race conditions when creating a pacticipant on postgres	 ([2c83985f](/../../commit/2c83985f))
* ensure latest version of rack is used to avoid vulnerability CVE-2018-16471	 ([996953f8](/../../commit/996953f8))


<a name="v2.27.4"></a>
### v2.27.4 (2018-11-15)


#### Bug Fixes

* handle race conditions when creating a pacticipant	 ([b3799670](/../../commit/b3799670))
* correct order of arguments for merging pacts	 ([f6cfb197](/../../commit/f6cfb197))


<a name="v2.27.3"></a>
### v2.27.3 (2018-11-01)


#### Features

* add LogQuietener to example config.ru	 ([2f014f07](/../../commit/2f014f07))
* Rename database logger delegate to LogQuietener	 ([34f44bcb](/../../commit/34f44bcb))
* create delegate for database logger to tone down the 'table does not exist' errors that freak people out at startup	 ([573d204b](/../../commit/573d204b))

* **semantic-logging**
  * set logger for SuckerPunch and tests	 ([201eb331](/../../commit/201eb331))
  * allow ruby standard logger to be configured to ensure backwards compatibility	 ([cfbb704c](/../../commit/cfbb704c))

* **tagged-pact-versions**
  * ensure triggered webhooks are deleted when pact versions are deleted	 ([288475f1](/../../commit/288475f1))
  * add endpoint to view and delete a collection of pact versions by tag	 ([615025e9](/../../commit/615025e9))

* **logging**
  * implement structured logging	 ([a9133bd5](/../../commit/a9133bd5))


#### Bug Fixes

* correct foreign key between AllPactPublications and PactVersion	 ([59f76c74](/../../commit/59f76c74))
* ensure bundle install for pact_broker:dev:setup uses correct Gemfile	 ([94f3a5f2](/../../commit/94f3a5f2))
* Fix some invalid HTML	 ([0c9a08a8](/../../commit/0c9a08a8))

* **openssl**
  * simplify certificate test for latest LibreSSL/OpenSSL libs	 ([cce79390](/../../commit/cce79390))


<a name="v2.27.2"></a>
### v2.27.2 (2018-09-14)


#### Features

* use application/yaml instead of application/x-yaml to match Swaggerhub	 ([067d6ac7](/../../commit/067d6ac7))
* treat .yaml requests as having header Accept: application/x-yaml	 ([1c8e199f](/../../commit/1c8e199f))

* **webhook whitelist**
  * allow hosts to be whitelisted using * domains	 ([150858a1](/../../commit/150858a1))


#### Bug Fixes

* **content-type**
  * convert 404 content-type to application/hal+json #235	 ([83958db7](/../../commit/83958db7))


<a name="v2.27.0"></a>
### v2.27.0 (2018-09-07)


#### Features

* add ${pactbroker.consumerLabels} and ${pactbroker.providerLabels} to webhook templates	 ([afebbc5a](/../../commit/afebbc5a))


<a name="v2.26.1"></a>
### v2.26.1 (2018-09-07)


#### Features

* allow integrations to be exported in dot format (text/vnd.graphviz)	 ([ac609081](/../../commit/ac609081))
* eager load latest version for /pacticipants resource	 ([9ac2ba9b](/../../commit/9ac2ba9b))
* eager load pacticipant labels for /pacticipants resource	 ([01dd8669](/../../commit/01dd8669))


#### Bug Fixes

* **matrix**
  * gracefully handle and log when version is unresolved	 ([82fe19f1](/../../commit/82fe19f1))

* gracefully handle attempt to create a duplicate tag	 ([53bea8b4](/../../commit/53bea8b4))
* correct :false to false in verification decorator to correctly handle read only property providerName	 ([4af4ed1c](/../../commit/4af4ed1c))
* gracefully handle scenario where URL supplied in JSON body is not a String	 ([b0bb6044](/../../commit/b0bb6044))


<a name="v2.26.0"></a>
### v2.26.0 (2018-08-23)


#### Features

* change default value of base_equality_only_on_content_that_affects_verification_results to true	 ([615f0c90](/../../commit/615f0c90))
* renamed 'wip pacts' to 'pending pacts'	 ([11a56b5c](/../../commit/11a56b5c))


<a name="v2.25.0"></a>
### v2.25.0 (2018-08-09)


#### Features

* make contract_content_changed tag aware	 ([8e7d0e47](/../../commit/8e7d0e47))
* move "latest id" upsert logic into own class	 ([360d236f](/../../commit/360d236f))
* replace latest_verifications view with latest_verifications_for_provider_versions	 ([ee4fef99](/../../commit/ee4fef99))
* sort tags in text/plain version of /dashboard	 ([0a821490](/../../commit/0a821490))
* optimise data migrations that set pacticipant ids	 ([9a148b80](/../../commit/9a148b80))
* add pact_version_id to latest_pact_publication_ids table	 ([627ce6db](/../../commit/627ce6db))
* optimise query for loading latest verification for the latest pacts for each tag on index page	 ([8bc58442](/../../commit/8bc58442))
* add consumer_id to pact_publications table	 ([d520e228](/../../commit/d520e228))
* add consumer id and provider id to verifications table to speed up queries	 ([d5698901](/../../commit/d5698901))
* run data migrations on startup to ensure data created by old nodes is migrated when performing a rolling update	 ([ec59ba5b](/../../commit/ec59ba5b))
* move migrations on feature branch to run last	 ([78d31c49](/../../commit/78d31c49))
* remove refresh of materialized_matrix and materialized_head_matrix	 ([262af756](/../../commit/262af756))
* keep track of the latest verification for a pact version for each provider version, rather than calculating it	 ([110495a9](/../../commit/110495a9))
* store latest pact publication ids for each consumer version	 ([d239bfdf](/../../commit/d239bfdf))
* keep track of latest pact revision in table rather than calculating it	 ([e9cd9e1b](/../../commit/e9cd9e1b))
* move pb:wip-provider-pacts to beta:wip-provider-pacts	 ([3008140a](/../../commit/3008140a))
* make feature toggles case insensitive and space aware	 ([f4a03c0c](/../../commit/f4a03c0c))
* add feature toggle via environment variable PACT_BROKER_FEATURES	 ([f0737b97](/../../commit/f0737b97))
* keep track of the latest verification for a pact version for each provider version, rather than calculating it	 ([b4f18770](/../../commit/b4f18770))
* store latest pact publication ids for each consumer version	 ([c8fa5545](/../../commit/c8fa5545))
* keep track of latest pact revision in table rather than calculating it	 ([1db5b7ba](/../../commit/1db5b7ba))

* **index**
  * eager load latest verification for consumer and provider	 ([1bf61afc](/../../commit/1bf61afc))


#### Bug Fixes

* **index page**
  * correct pact URL when showing index with tags	 ([a5bda98f](/../../commit/a5bda98f))


<a name="v2.24.0"></a>
### v2.24.0 (2018-07-08)


#### Features

* disable wip-provider-pacts in production until the feature is passed alpha testing	 ([3f9a1c7](/../../commit/3f9a1c7))
* allow HAL docs to specify a context so that two relations with the same name in different resources don't clash	 ([fe85b0b](/../../commit/fe85b0b))
* add pb:diff relation to pact resource to view a diff with an arbitrary pact version	 ([3eaa79c](/../../commit/3eaa79c))
* add HAL documentation for the relations that were missing documentation	 ([6b04d70](/../../commit/6b04d70))
* add resource for "work in progress" pacts for a provider	 ([50c003b](/../../commit/50c003b))
* deprecate pacts relation in favour of pb:pacts in latest pacts resource	 ([ccdd46f](/../../commit/ccdd46f))
* add bash script to migrate pacts from one broker to another	 ([7d587d9](/../../commit/7d587d9))


<a name="v2.23.4"></a>
### v2.23.4 (2018-07-04)


#### Features

* deprecate provider relation in provider pacts resource in preference for pb:provider	 ([eda8cbf](/../../commit/eda8cbf))


#### Bug Fixes

* correct the logic for determining the deployment status in the matrix resource	 ([ad85db4](/../../commit/ad85db4))
* delete associated verification results when a pacticipant version is deleted	 ([ddec810](/../../commit/ddec810))


<a name="v2.23.3"></a>
### v2.23.3 (2018-06-27)


#### Bug Fixes

* add missing require in triggered_webhooks_decorator.rb	 ([c4adeaf](/../../commit/c4adeaf))


<a name="v2.23.2"></a>
### v2.23.2 (2018-06-25)


#### Bug Fixes

* ensure configured webhook headers are used when making request	 ([50c876f](/../../commit/50c876f))


<a name="v2.23.1"></a>
### v2.23.1 (2018-06-23)


#### Features

* respond correctly to OPTIONS requests	 ([c5d3937](/../../commit/c5d3937))


#### Bug Fixes

* add missing require to pact_triggered_webhooks	 ([aaf1755](/../../commit/aaf1755))


<a name="v2.23.0"></a>
### v2.23.0 (2018-06-20)


#### Features

* include test webhook request in execution response body	 ([7518098](/../../commit/7518098))
* use the latest matching pact or verification to test webhook execution, or a placeholder if either is not found	 ([273078b](/../../commit/273078b))
* add resource to view the triggered webhooks for a verification result	 ([c3e8df0](/../../commit/c3e8df0))
* add resource to view the triggered webhooks for a pact publication	 ([00f60c1](/../../commit/00f60c1))
* allow "global" webhooks (matching all consumers and providers) to be triggered by pact or verification publication	 ([19f7060](/../../commit/19f7060))
* allow webhook with optional consumer and/or provider to be created by posting to /webhooks	 ([b15ba85](/../../commit/b15ba85))
* add consumer and provider objects to webhook resource	 ([e60460e](/../../commit/e60460e))
* move $.message to $.error.message in error response body	 ([803c025](/../../commit/803c025))
* only show backtrace in error response for non production environments	 ([665ac23](/../../commit/665ac23))
* change version ordering to sort by date by default	 ([6552b46](/../../commit/6552b46))
* raise explicit error if a matrix query is done for a version with a tag that does not exist	 ([8f64288](/../../commit/8f64288))

* **consumer or provider webhooks**
  * refactor webhooks resource classes and add consumer and provider webhook links to pact resource	 ([9321c73](/../../commit/9321c73))
  * change pact webhook status URL	 ([2445b1e](/../../commit/2445b1e))
  * allow a webhook to be defined for either a consumer OR provider	 ([37a62be](/../../commit/37a62be))


#### Bug Fixes

* ensure non utf-8 characters in the webook response do not cause an error in the Pact Broker response body	 ([a5ae5bf](/../../commit/a5ae5bf))
* update sintra to >= 2.0.2 to fix css vulnerability	 ([3023408](/../../commit/3023408))


<a name="v2.22.0"></a>
### v2.22.0 (2018-06-11)


#### Features

* allow whitelist configurations to be loaded from database	 ([19cb83f](/../../commit/19cb83f))


<a name="v2.21.0"></a>
### v2.21.0 (2018-06-10)


#### Features

* add ${pactbroker.consumerVersionTags} and ${pactbroker.providerVersionTags} to webhook templates	 ([e5121b1](/../../commit/e5121b1))
* add ${pactbroker.verificationResultUrl} to webhook templates	 ([e19c9c9](/../../commit/e19c9c9))
* redact potentially sensitive headers in the webhook resource	 ([619c7e9](/../../commit/619c7e9))
* add ${pactbroker.githubVerificationStatus} to webhook templates	 ([abccf7a](/../../commit/abccf7a))
* add ${pactbroker.providerVersionNumber} to webhook templates	 ([86bc1ec](/../../commit/86bc1ec))


#### Bug Fixes

* correctly trigger contract_content_changed webhooks when first version of a pact is published	 ([73a06ff](/../../commit/73a06ff))
* correctly handle template parameters in URL when rendering webhook resource	 ([a4b69db](/../../commit/a4b69db))
* correct call to execute webhooks when pact changes	 ([076afe6](/../../commit/076afe6))
* ensure webhook hosts cannot contain templated parameters	 ([fe05919](/../../commit/fe05919))
* allow pact broker template parameter in URL	 ([c91d04e](/../../commit/c91d04e))
* correct logic for showing webhook response bodies in logs when a whitelist is configured	 ([db2f9d1](/../../commit/db2f9d1))


<a name="v2.20.0"></a>
### v2.20.0 (2018-06-03)


#### Features

* only log webhook response details when a webhook host whitelist has been configured	 ([3e1c562](/../../commit/3e1c562))
* validate webhook host against configurable list on creation	 ([077e37f](/../../commit/077e37f))
* validate webhook scheme and http method against configurable lists on creation	 ([d7a2b0a](/../../commit/d7a2b0a))
* add ${pactbroker.consumerVersionNumber} to webhook templates	 ([d525527](/../../commit/d525527))


#### Bug Fixes

* correct all content types that were application/json to application/hal+json	 ([690e39b](/../../commit/690e39b))


<a name="v2.19.2"></a>
### v2.19.2 (2018-05-29)


#### Features

* load latest verification for consumer/provider via relationship rather than repository	 ([13b7c6e](/../../commit/13b7c6e))
* include more columns in latest_verifications_for_consumer_version_tags to avoid having to do extra queries for pact_versions and provider_versions	 ([e366af4](/../../commit/e366af4))
* optimise queries for index page with tags	 ([524e08d](/../../commit/524e08d))
* create view for latest verifications for consumer version tags	 ([eb67511](/../../commit/eb67511))
* log pact content as debug instead of info when publishing	 ([d116157](/../../commit/d116157))
* allow pact equality to be based only on the content that affects verification results	 ([bf8130f](/../../commit/bf8130f))


#### Bug Fixes

* temporarily redact webhook response body from UI for security purposes	 ([becf20c](/../../commit/becf20c))
* handle race condition causing unique constraint violation when creating pacticipant versions	 ([6c75ebd](/../../commit/6c75ebd))


<a name="v2.19.1"></a>
### v2.19.1 (2018-05-18)


#### Features

* rename relations in pact diff view	 ([8c3c62e](/../../commit/8c3c62e))


#### Bug Fixes

* add pact name back into title of deprecated pacts relation of provider pacts resource	 ([f5f002a](/../../commit/f5f002a))
* set correct content type for verification result resources	 ([c177fdd](/../../commit/c177fdd))


<a name="v2.19.0"></a>
### v2.19.0 (2018-05-03)


#### Features

* create endpoint to compare arbitrary pact versions, ignoring interaction/message order	 ([15f0688](/../../commit/15f0688))
* add endpoint to retrieve a pact version by its pact content sha	 ([a519731](/../../commit/a519731))
* include pact revision number and verification number in badge svg comment	 ([82b59ef](/../../commit/82b59ef))
* add pb:version-tag relation to pacticipant resource	 ([0704772](/../../commit/0704772))
* create endpoints for retrieving all pact versions for a provider, with and without a tag.	 ([d7011b2](/../../commit/d7011b2))
* update matrix UI to allow _all_ versions with a particular tag to be specified	 ([278b3ea](/../../commit/278b3ea))
* allow matrix to be queried for _all_ versions with a given tag	 ([cac3023](/../../commit/cac3023))


#### Bug Fixes

* correct logic for finding latest verification for revised pacts	 ([8fb28ee](/../../commit/8fb28ee))
* do not invoke error reporters for validation errors	 ([57eed65](/../../commit/57eed65))


<a name="v2.18.0"></a>
### v2.18.0 (2018-04-05)


#### Features

* add link to matrix from HTML pact page	 ([f9e3c23](/../../commit/f9e3c23))
* sort tags in dashboard API response	 ([d2fd090](/../../commit/d2fd090))
* add rake task to clean unused data to improve performance	 ([fc705a2](/../../commit/fc705a2))


#### Bug Fixes

* show JSON view when *any* error occurs creating the HTML view for a pact.	 ([e4342f0](/../../commit/e4342f0))
* only show verification matrix number when verification is present	 ([766f7c0](/../../commit/766f7c0))
* correctly display interaction with nil description in HTML view	 ([56528d3](/../../commit/56528d3))


<a name="v2.17.1"></a>
### v2.17.1 (2018-03-30)


#### Bug Fixes

* refresh matrix and head_matrix tables	 ([bf36c61](/../../commit/bf36c61))


<a name="v2.17.0"></a>
### v2.17.0 (2018-03-30)


#### Features

* ensure migrations in optimise_head_matrix work on mysql	 ([35874a9](/../../commit/35874a9))
* show verification number in matrix when viewing all results	 ([5693430](/../../commit/5693430))
* redact auth headers from rack env used to report errors	 ([94f8f13](/../../commit/94f8f13))
* add api error reporters	 ([579fa39](/../../commit/579fa39))
* log debug message when loading configuration setting from database	 ([9ffcc1a](/../../commit/9ffcc1a))
* optimise head matrix refresh when adding or deleting tags	 ([263c2a4](/../../commit/263c2a4))
* disable sinatra dump_errors	 ([d59c7e5](/../../commit/d59c7e5))
* send padrino logs to a file in the log dir by default	 ([7408be0](/../../commit/7408be0))

* **matrix ui**
  * add tooltip explaining the situation when verification date is before pact publication date	 ([fd6e1c9](/../../commit/fd6e1c9))
  * change default to show all results	 ([f7bea07](/../../commit/f7bea07))


#### Bug Fixes

* ensure publishing a verification does not cause a unique constraint violation	 ([ecfb385](/../../commit/ecfb385))
* optimize matrix query to speed up lengthy pact publication times	 ([e09d528](/../../commit/e09d528))
* ensure matrix is updated when pacticipant is deleted	 ([6c11cbe](/../../commit/6c11cbe))
* delete pacticipant labels before deleting pacticipant	 ([18b9b7e](/../../commit/18b9b7e))


<a name="v2.16.1"></a>
### v2.16.1 (2018-03-08)


#### Features

* turn off sinatra show_exceptions when rack_env is production	 ([e961afe](/../../commit/e961afe))
* add error testing endpoints	 ([4e01407](/../../commit/4e01407))


<a name="v2.16.0"></a>
### v2.16.0 (2018-03-05)

#### Features

* upgrade haml to 5.0	 ([4415686](/../../commit/4415686))
* upgrade sequel to 5.6	 ([a37c59a](/../../commit/a37c59a))
* abbreviate git shas in index and matrix UIs	 ([9a21e10](/../../commit/9a21e10))
* add latest provider version tag names to dashboard UI	 ([de179d7](/../../commit/de179d7))
* created dashboard API	 ([044bab7](/../../commit/044bab7))

* **matrix**
  * make index refresh happen synchronously to prevent data corruption	 ([acd64e6](/../../commit/acd64e6))
  * speed up query to refresh index	 ([011d7c9](/../../commit/011d7c9))
  * refresh head matrix asynchronously to speed up pact publishing and tagging	 ([989e6e3](/../../commit/989e6e3))
  * speed up matrix query for latestby=cvpv and latestby=cvp	 ([6ae039d](/../../commit/6ae039d))

* **index**
  * sort verifications by execution date	 ([2523982](/../../commit/2523982))
  * show tag names as slugs	 ([117c89b](/../../commit/117c89b))

* **matrix ui**
  * rename "rows" to "results"	 ([2023265](/../../commit/2023265))
  * show row count	 ([b50bd9a](/../../commit/b50bd9a))
  * remove logic for hiding links until I can get it right	 ([107fca2](/../../commit/107fca2))
  * correct logic for hiding pact links	 ([825af6d](/../../commit/825af6d))
  * don't show potentially confusing links for overwritten pact revisions	 ([ed7498a](/../../commit/ed7498a))
  * add links to all resources referenced in matrix	 ([2958ae8](/../../commit/2958ae8))
  * add tags	 ([869d49d](/../../commit/869d49d))

* **dashboard api**
  * correct latest verification results	 ([d02ea24](/../../commit/d02ea24))
  * fix query for displaying dashboard with tags	 ([924aaae](/../../commit/924aaae))
  * optimise dashboard query by creating manual materialized views for the matrix	 ([494f553](/../../commit/494f553))
  * add plain text content type for easy debugging	 ([317a64d](/../../commit/317a64d))
  * speed up loading of verification tags	 ([a3aea48](/../../commit/a3aea48))
  * include verification tags	 ([e8d0fae](/../../commit/e8d0fae))
  * add pact tags	 ([0c79440](/../../commit/0c79440))

#### Bug Fixes

* **matrix**
  * correct logic for selecting matrix rows on MySQL	 ([06f6dd4](/../../commit/06f6dd4))
  * ensure matrix for latest consumer version/provider version shows correct results when a pact is published, published again for the same version with different content, then published again for the same version with the original content.	 ([679eec1](/../../commit/679eec1))

* **matrix ui**
  * fix provider version sorting	 ([611ab7e](/../../commit/611ab7e))

<a name="v2.15.0"></a>
### v2.15.0 (2018-02-26)

#### Features

* upgrade to latest versions of padrino-core and sinatra to fix CVE-2018-7212	 ([08ba1cb](/../../commit/08ba1cb))

* **http**
  * set http options globally	 ([cdf36ba](/../../commit/cdf36ba))

* **ssl**
  * allow single certificates to be uploaded	 ([9417f10](/../../commit/9417f10))

<a name="v2.14.0"></a>
### v2.14.0 (2018-02-15)

#### Features

* **matrix ui**
  * add home link	 ([3f74e7e](/../../commit/3f74e7e))

* **index**
  * add link to show/hide latest tags	 ([412a2d3](/../../commit/412a2d3))

* change URL for retrieving latest version so that it does not clash with a version called "latest"	 ([8e45062](/../../commit/8e45062))
* add endpoints to get latest pacticipant version and latest tagged version	 ([aa60a85](/../../commit/aa60a85))
* elegantly handle long service names in index.	 ([ad8da50](/../../commit/ad8da50))

#### Bug Fixes

* return overwritten pact publication as latest if non exists as a latest version when rendering verification	 ([8217209](/../../commit/8217209))
* #184 Escape username before asigning it to URI userinfo attribute	 ([81bb779](/../../commit/81bb779))
* remove non UTF-8 chars from webhook response bodies before saving the logs to the (UTF-8 encoded) database table	 ([0ee5b0b](/../../commit/0ee5b0b))
* ensure webhook dependencies are saved before executing	 ([9a89d07](/../../commit/9a89d07))

* **matrix badge**
  * correct status of pact when consumer and provider version tags are specified	 ([0eb7429](/../../commit/0eb7429))

<a name="v2.13.1"></a>
### v2.13.1 (2018-01-12)

#### Features

* remove runtime dependency on webrick	 ([1ae7a6e](/../../commit/1ae7a6e))

<a name="v2.13.0"></a>
### v2.13.0 (2018-01-11)

#### Features

* ensure latest pact version is returned when searching by pact version sha	 ([1d2adc6](/../../commit/1d2adc6))
* rename 'pact_publication' trigger type to 'publication'	 ([9fe0ff0](/../../commit/9fe0ff0))

* **certificates**
  * load webhook certificates from database	 ([c72ab28](/../../commit/c72ab28))

* **matrix ui**
  * add checkbox for latest version	 ([7743ecc](/../../commit/7743ecc))
  * add limit and latestby to form	 ([c4136bd](/../../commit/c4136bd))
  * do not log validation errors	 ([f201d1d](/../../commit/f201d1d))
  * add form	 ([cbf0837](/../../commit/cbf0837))

* **matrix badges**
  * add badge for provider/tag and consumer/tag	 ([d69c8e6](/../../commit/d69c8e6))

* **verification webhooks**
  * update hal browser documentation	 ([c2b31b4](/../../commit/c2b31b4))
  * invoke verification webhooks on publication of verification	 ([04ed1cc](/../../commit/04ed1cc))
  * alter logic to select only the relevant webhooks when the pact has changed	 ([ec18943](/../../commit/ec18943))
  * default to contract changed event when no events specified, for backwards compatibility	 ([9fe8d47](/../../commit/9fe8d47))
  * add events to webhooks to allow differentiation between pact and verification webhooks	 ([356c023](/../../commit/356c023))

* **publish test result**
  * allow json test results to be published with the verification result	 ([528034c](/../../commit/528034c))

#### Bug Fixes

* create selector objects when viewing matrix URL with consumer and provider	 ([e733bae](/../../commit/e733bae))

<a name="v2.12.0"></a>
### v2.12.0 (2017-11-29)

#### Features
* changed date published to time ago in words, with full date as mouseover (#145) ([b28f9c3](/../../commit/b28f9c3))

#### Bug Fixes

* fixed issue that caused uninitialized constant PactBroker::Api::Resources::BaseResource (NameError) when running pact_broker with passenger..	 ([0b21a62](/../../commit/0b21a62))

<a name="v2.10.0"></a>
### v2.10.0 (2017-11-11)

#### Features

* **prod pacts in index**
  * allow all tags to be shown on index	 ([0a1f0ee](/../../commit/0a1f0ee))
  * allow tags shown in index to be configured via query string	 ([4eca8ee](/../../commit/4eca8ee))
  * show pacts tagged as the 'prod' or 'production' versions on the index page	 ([b58b7a3](/../../commit/b58b7a3))

* **index page**
  * truncate git shas in table	 ([94da4c7](/../../commit/94da4c7))

<a name="v2.9.0"></a>
### v2.9.0 (2017-11-09)

#### Features

* **webhook templating**
  * add support for ${pactbroker.pactUrl} in query and body	 ([0eed596](/../../commit/0eed596))

* **matrix** _(note that the matrix resource is still in beta, and there may be breaking changes in the future)_
  * allow query to determine if a particular pacticipant version is compatible with the latest tagged versions of all its dependencies	 ([ba4a1cc](/../../commit/ba4a1cc))

<a name="v2.8.0.beta.5"></a>
### v2.8.0.beta.5 (2017-11-06)

#### Features

* **matrix**
  * fix matrix data types for MySQL	 ([42c5478](/../../commit/42c5478))
  * improve reason when no results are found	 ([473abbe](/../../commit/473abbe))
  * change groupby param to latestby	 ([a6a8ba2](/../../commit/a6a8ba2))
  * ensure correct row is returned when a pact is revised, then verified	 ([7f37644](/../../commit/7f37644))
  * return most recent rows first	 ([cfa2109](/../../commit/cfa2109))
  * allow a limit to be specified	 ([2a11334](/../../commit/2a11334))
  * return most recent rows first	 ([e896b7b](/../../commit/e896b7b))
  * use views to create matrix query	 ([8488212](/../../commit/8488212))
  * add matrix view	 ([852324a](/../../commit/852324a))

<a name="v2.8.0.beta.4"></a>
### v2.8.0.beta.4 (2017-11-03)

#### Bug Fixes

* add missing require	 ([14d7d02](/../../commit/14d7d02))

<a name="v2.7.0.beta.3"></a>
### v2.7.0.beta.3 (2017-11-01)

#### Features

* **matrix**
  * implement querying by latest without a tag	 ([3d78f79](/../../commit/3d78f79))
  * update query to handle tag and latest flag	 ([c5c800f](/../../commit/c5c800f))
  * update validation of selectors to allow tag and latest flag to be specified	 ([0fa33f1](/../../commit/0fa33f1))
  * parse latest=true and tag=TAG in matrix query	 ([abcab9e](/../../commit/abcab9e))
  * update validation to allow latest tag to be specified	 ([6da6e02](/../../commit/6da6e02))
  * allow version to be specified by latest_tag	 ([fe498a7](/../../commit/fe498a7))

* **pacticipant**
  * expose repositoryUrl in resource	 ([8f0f16a](/../../commit/8f0f16a))

#### Bug Fixes

* correct captialization in require	 ([db2e676](/../../commit/db2e676))

<a name="v2.7.0.beta.2"></a>
### v2.7.0.beta.2 (2017-10-31)

#### Features

* **matrix**
  * add reason text to summary	 ([f979210](/../../commit/f979210))
  * add text/plain content type for easier visualisation of matrix resource in terminal	 ([bab7720](/../../commit/bab7720))
  * allow matrix rows to be returned for all versions of a pacticipant	 ([6d37545](/../../commit/6d37545))
  * allow multiple verification statuses to be queried for using status[]=	 ([fba2771](/../../commit/fba2771))
  * allow success param to be specified in query params	 ([2fb5817](/../../commit/2fb5817))
  * change query params for matrix to use q[][pacticipant]=? and q[][version]=?	 ([e3913f7](/../../commit/e3913f7))
  * return failure and success lines in matrix response, and a summary indicating whether the specified versions are compatible or not	 ([8783ef8](/../../commit/8783ef8))
  * add method to find all matrix lines for a list of versions, regardless of verification status	 ([52755fd](/../../commit/52755fd))
  * add pact publication and verification dates to response	 ([f0cc32b](/../../commit/f0cc32b))
  * add validation errors to matrix resource	 ([7f91710](/../../commit/7f91710))
  * allow matrix columns to be sorted	 ([7d22eb8](/../../commit/7d22eb8))
  * add simple ui	 ([36f9480](/../../commit/36f9480))
  * add endpoint for consumer/provider verification matrix	 ([6925dcb](/../../commit/6925dcb))

* rename 'hal browser' links to 'api browser'	 ([11d3464](/../../commit/11d3464))
* use timestamp migrator during app startup	 ([a87f393](/../../commit/a87f393))
* convert paths ending in .json to Accept: application/hal+json	 ([d81f129](/../../commit/d81f129))

* **auth**
  * cascade UI before diagnostic api and broker api	 ([1b95461](/../../commit/1b95461))

* **verifications**
  * create and link provider version resource when verification is published	 ([3014a8b](/../../commit/3014a8b))

#### Bug Fixes

* show webhook status as not_run when all triggered webhooks are not_run	 ([2d014b2](/../../commit/2d014b2))

<a name="v2.7.0.beta.1"></a>
### v2.7.0.beta.1 (2017-10-16)

#### Features

* **prod pacts in index**
  * show pacts tagged as the 'prod' or 'production' versions on the index page	 ([b58b7a3](/../../commit/b58b7a3))

<a name="v2.6.0"></a>
### v2.6.0 (2017-10-06)

#### Features

* add configuration option for check_for_potential_duplicate_pacticipant_names	 ([6ab3fda](/../../commit/6ab3fda))

#### Bug Fixes

* add webhook_retry_schedule and semver_formats to list of configuration options that can be saved to the database	 ([5bab062](/../../commit/5bab062))
* delete related triggered webhooks when webhook is deleted	 ([48f9853](/../../commit/48f9853))
* use strict mode when using mysql	 ([f991e15](/../../commit/f991e15))

<a name="v2.5.1"></a>
### v2.5.1 (2017-09-26)

#### Bug Fixes

* **badges**
  * do not allow caching	 ([d7e73c3](/../../commit/d7e73c3))

<a name="v2.5.0"></a>
### v2.5.0 (2017-09-25)

#### Features

* **heartbeat resource**
  * cache json response body	 ([f2ac0f5](/../../commit/f2ac0f5))

* **webhook status**
  * delete webhook objects related to previous revisions of a pact when deleting a pact publication	 ([a053623](/../../commit/a053623))
  * delete related triggered webhooks and executions when pact publication is deleted	 ([3dc590c](/../../commit/3dc590c))
  * set any triggered webhooks in 'retrying' status to 'failed' on startup	 ([1f2305b](/../../commit/1f2305b))
  * migrate webhook execution data to triggered webhooks	 ([9f46d86](/../../commit/9f46d86))
  * consider http status < 300 to be a webhook failure	 ([7ef595a](/../../commit/7ef595a))
  * log unhandled suckerpunch errors	 ([4cc779d](/../../commit/4cc779d))
  * log number of seconds until next webhook attempt in webhook logs	 ([5d16330](/../../commit/5d16330))
  * display attempts made and attempts remaining in webhook status resource	 ([648e1c3](/../../commit/648e1c3))
  * move webhook retry schedule to configuration	 ([f2d92f3](/../../commit/f2d92f3))
  * ensure triggered webhook and webhook execution objects are saved to database even when webhook fails and response code is 500	 ([88ba2ac](/../../commit/88ba2ac))
  * redact authorization headers in webhook logs	 ([10efddb](/../../commit/10efddb))
  * implement PUT for webhook resource	 ([7266b1e](/../../commit/7266b1e))
  * add endpoint for triggered webhook execution logs	 ([ad81d20](/../../commit/ad81d20))

* **hal browser**
  * use name over title in embedded resource heading	 ([6c61da7](/../../commit/6c61da7))
  * improve readability of link collections	 ([0a9bc8c](/../../commit/0a9bc8c))
  * use name and title from self link when not specified in embedded resource	 ([354374c](/../../commit/354374c))

* **versions resource**
  * deprecate versions and pacticipant links in favour of pb:versions and pb:pacticipants	 ([94f395e](/../../commit/94f395e))

* **badges**
  * only cache successful badge responses from shields.io	 ([e5f08ad](/../../commit/e5f08ad))
  * use simple in-memory cache for badges	 ([2453c55](/../../commit/2453c55))
  * show message about enabling public badge access when disabled	 ([6fc78ff](/../../commit/6fc78ff))
  * show badge in HTML pact and display markdown when clicked	 ([e9b632a](/../../commit/e9b632a))
  * changed configuration property name from 'enable_badge_resources' to 'enable_public_badge_access'	 ([83540e5](/../../commit/83540e5))

* **resources**
  * improve usage of title and name attributes	 ([915a7ee](/../../commit/915a7ee))

* **pact resource**
  * improve usage of name and title fields	 ([3a9a178](/../../commit/3a9a178))
  * add link relation for all pact versions	 ([d5ea068](/../../commit/d5ea068))

* **gems**
  * upgrade webmachine to 1.5.0	 ([d23fedc](/../../commit/d23fedc))

#### Bug Fixes

* return correct "latest" verification when a verification has been published for a pact with a revision	 ([f2b4c9f](/../../commit/f2b4c9f))
* sequel migration 25 for mysql	 ([920c363](/../../commit/920c363))
* sequel migration 19 for mysql	 ([0ee48e1](/../../commit/0ee48e1))

<a name="v2.4.2"></a>
### v2.4.2 (2017-09-07)

#### Bug Fixes

* add missing require	 ([92bf349](/../../commit/92bf349))

<a name="v2.4.1"></a>
### v2.4.1 (2017-09-07)

#### Bug Fixes

* allow resource identifiers to contain escaped forward slashes	 ([d875079](/../../commit/d875079))

<a name="v2.4.0"></a>
### v2.4.0 (2017-07-31)
* 3a03f41 - fix(publish verification result): Fix Location header for newly created resource (Beth Skurrie, Mon Jul 31 10:49:37 2017 +1000)
* 3b0f390 - feat(pacticipant labels): Add HAL link to pacticipants resource to find pacticipants by label. (Beth Skurrie, Mon Jul 24 08:17:36 2017 +1000)
* 588d2ad - fix(pacticipant and pacticipants resources): Add correctly capitalised and namespaced properties and relations. Added deprecation warnings to existing incorrect properties and relations. (Beth Skurrie, Mon Jul 24 08:14:52 2017 +1000)
* ab11f56 - feat(pacticipant labels): Adds embedded label resources to pacticipant resource. (Beth Skurrie, Fri Jul 21 18:03:15 2017 +1000)
* 57086cf - feat(pacticipant labels): Adds /pacticipants/label/LABEL_NAME resource to retrieve pacticipants by label. (Beth Skurrie, Fri Jul 21 14:07:08 2017 +1000)
* 4b44331 - feat(pacticipant labels): Adds pacticipant label resource with GET, PUT and DELETE (Beth Skurrie, Fri Jul 21 13:18:18 2017 +1000)
* c5af7e1 - feat(badges): Allow badge config settings to be saved to/loaded from database (Beth Skurrie, Fri Jul 14 20:50:02 2017 +1000)

#### 2.3.0 (2017-07-14)
* 3ac4351 - fix(potential duplicate pacticipant names): Make duplicate logic smarter. Fixes https://github.com/pact-foundation/pact_broker/issues/35 (Beth Skurrie, Tue Jul 11 10:30:11 2017 +1000)
* 81979b1 - add basic auth example to duplicate pacticipant error/help message (Fitzgerald, Andrew, Mon Jul 10 00:11:25 2017 -0400)
* bc54321 - feat(badges): Add endpoint to retrieve badge for latest untagged pact (Beth Skurrie, Fri Jul 7 10:15:29 2017 +1000)
* 5a3b149 - feat(badges): Add endpoint to retrieve badge for latest tagged pact (Beth Skurrie, Fri Jul 7 09:32:24 2017 +1000)
* 78c888b - feat(badges): Use static images when shields.io base URL is not configured. (Beth Skurrie, Fri Jul 7 08:41:35 2017 +1000)
* b30c368 - feat(badges): Allow shields.io base URL to be configured (Beth Skurrie, Fri Jul 7 08:31:47 2017 +1000)
* d8b2cec - feat(badges): Added configuration for turning badge resources on or off (Beth Skurrie, Fri Jul 7 08:25:48 2017 +1000)
* 2e43b5f - feat(badges): Added read timeout of 1000ms for HTTP call to create badge. (Beth Skurrie, Thu Jul 6 07:48:39 2017 +1000)
* 6bdae00 - fix(publish verification): Corrected pact finding params when publishing a verification. (Beth Skurrie, Thu Jul 6 07:30:38 2017 +1000)
* 2508eba - feat(badges): Allow pacticipant initials to be used where names are too long for the badge (Beth Skurrie, Wed Jul 5 14:49:07 2017 +1000)
* f7a36b7 - feat(badges): Return static badge when there is an error creating a dynamic one (Beth Skurrie, Wed Jul 5 10:14:18 2017 +1000)
* 24860b3 - feat(badges): Add badge svg endpoint for latest pact (Beth Skurrie, Tue Jul 4 15:28:28 2017 +1000)

#### 2.2.0 (2017-07-04)
* 788c5d0 - chore(gems): Lock rack and red-carpet gem versions for hakiri (Beth Skurrie, Tue Jul 4 10:28:15 2017 +1000)
* f1abebe - chore(gems): Upgrade pact gems (Beth Skurrie, Tue Jul 4 10:10:55 2017 +1000)
* 5bccca2 - chore(gems): Upgrade rack-protection and padrino-core gems (Beth Skurrie, Tue Jul 4 10:07:58 2017 +1000)
* 5c1392d - chore(build): Add code climate test coverage reporter (Beth Skurrie, Tue Jul 4 09:02:09 2017 +1000)
* 6e73420 - chore(build): Add bundle-audit to build (Beth Skurrie, Tue Jul 4 08:09:49 2017 +1000)
* de9f493 - fix(pact versions decorator): Corrected use of title and name (Beth Skurrie, Mon Jul 3 19:45:28 2017 +1000)
* 90d4410 - feat(HTML pact): Add home link to HTML pact (Beth Skurrie, Mon Jul 3 16:57:57 2017 +1000)
* 4eb2095 - feat(HTML pact): Add tag names next to consumer version number (Beth Skurrie, Mon Jul 3 16:56:56 2017 +1000)
* 1f66b6d - feat(version): Add HAL links to pacts from version resource (Beth Skurrie, Mon Jul 3 16:34:34 2017 +1000)
* 3f61fb3 - feat(retrieve latest pact): Add HAL links for latest-untagged and latest/{tag} (Beth Skurrie, Mon Jul 3 16:17:54 2017 +1000)

#### 2.1.1 (2017-07-03)
* f7af21a - fix(gemspec) (Beth Skurrie, Mon Jul 3 09:53:02 2017 +1000)

#### 2.1.0 (2017-07-03)
* 53f0b5e - feat(get latest untagged pact): Add /latest-untagged endpoint to return the latest untagged pact (Beth Skurrie, Mon Jul 3 08:31:18 2017 +1000)
* a963fce - Add pact_broker:db:version task. (Beth Skurrie, Thu Jun 29 20:29:55 2017 +1000)
* 7ee134f - Add basic auth (authentication) to the UI, but no authorization (Beth Skurrie, Mon Jun 26 10:44:07 2017 +1000)

#### 2.0.5 (2017-06-15)
* e924c96 - Fixed webhook deletion bug (Beth Skurrie, Tue Jun 13 10:04:33 2017 +1000)

#### 2.0.4 (2017-06-02)
* 99e1c25 - Turn off http_origin checking for https://github.com/pact-foundation/pact_broker/issues/108 (Beth Skurrie, Fri Jun 2 16:27:38 2017 +1000)
* e58f609 - Add favicon.ico (Beth Skurrie, Mon May 29 15:02:22 2017 +1000)
* 2780f0a - Add pull request guidelines. (Beth Skurrie, Mon May 29 11:45:04 2017 +1000)

#### 2.0.3 (2017-05-17)
* c03b871 - Make specs pass for sqlite, postgres and mysql. At the same time. Amazing. (Beth Skurrie, Sun May 28 10:22:20 2017 +1000)
* ae2b62f - Remove inner query from latest_verifications definition for MySQL (#105) (Beth Skurrie, Sat May 27 15:11:26 2017 +1000)
* f451d35 - Add mysql build to travis for #106 (Beth Skurrie, Sat May 27 15:09:42 2017 +1000)
* 91178c2 - Altering config and travis to run against sqlite and postgres. (Beth Skurrie, Sat May 27 14:08:34 2017 +1000)
* 4c52061 - Use a simpler and more efficient algorithm for updating version orders. (Beth Skurrie, Mon May 22 13:29:07 2017 +1000)
* ba5b60c - Created indexes on pacticipant, version and tag tables. #87 (Beth Skurrie, Sun May 21 16:18:49 2017 +1000)
* 0ffad10 - Do not validate incoming consumer version number if order_versions_by_date is true. (Beth Skurrie, Sun May 21 15:46:54 2017 +1000)

#### 2.0.2 (2017-05-17)
* 0e4d4bf - Add missing require for migration_helper (Beth Skurrie, Fri May 19 14:16:38 2017 +1000)

#### 2.0.1 (2017-05-17)
* 8d105aa - Allow an application version to be deleted via the API. (Beth Skurrie, Fri May 19 10:39:16 2017 +1000)
* 025b0f7 - Ensure version numbers that don't conform to the semver2 spec don't cause errors when sorting versions. #103 (Beth Skurrie, Fri May 19 09:58:50 2017 +1000)
* ca6d88e - Corrected hal link rels that had missing curies (prepended "pb:") (Beth Skurrie, Thu May 18 10:20:06 2017 +1000)
* 1cabd5e - Use Rack::Protection. (Beth Skurrie, Tue May 16 10:13:40 2017 +1000)
* 2a3bbd1 - Return 404 instead of 500 when Ruby standard URI lib can't parse the URI. https://github.com/pact-foundation/pact_broker/issues/101 (Beth Skurrie, Tue May 16 09:45:37 2017 +1000)

#### 2.0.0 (2017-05-16)

#### 2.0.0.beta.8 (2017-05-15)
* e931b48 - Enable configuration settings to be saved to and loaded from the database. (Beth Skurrie, Mon May 15 12:34:44 2017 +1000)
* c3976e4 - Set timezones so dates in the UI and API are shown in the configured local time. (Beth Skurrie, Mon May 15 08:53:13 2017 +1000)
* 4da62e8 - Add publication date of latest pact to UI front page. (Beth Skurrie, Sun May 14 08:38:42 2017 +1000)
* 8633b08 - Set X-Pact-Broker-Version header in all responses (Beth Skurrie, Fri May 12 16:39:09 2017 +1000)

#### 2.0.0.beta.7 (2017-05-12)
* 741bf96 - Include information about missing verifications in the latest verifications resource. Only set success to be true when all pacts have been successfully verified. (Beth Skurrie, Fri May 12 14:59:48 2017 +1000)
* 64f20c6 - Allow one, two or three "parts" in the application version number. Eg. 12, 3.4 and 1.2.400 are all valid. (Beth Skurrie, Wed May 10 16:19:07 2017 +1000)

#### 2.0.0.beta.6 (2017-05-09)
* 8f1c911 - Ensure all resources provide application/hal+json. (Beth Skurrie, Tue May 9 18:32:37 2017 +1000)

#### 2.0.0.beta.5 (2017-05-08)
* 4b88c4d - Add success flag to the resource for the latest verifications for a consumer version to indicate the overall success or failure of the verification results for that version. (Beth Skurrie, Mon May 8 10:54:31 2017 +1000)

#### 2.0.0.beta.4 (2017-05-02)
* e5c14d1 - Renamed verification to verification-result in link relations and URLs (Beth Skurrie, Tue May 2 13:04:01 2017 +1000)
* 803ea44 - Add endpoint to show a verification. (Beth Skurrie, Mon May 1 08:52:12 2017 +1000)

#### 2.0.0.beta.3 (2017-04-29)
* 7059a7e - Insert pact_publications without a specified ID so that the inbuilt sequence is kept in sync. (Beth Skurrie, Sat Apr 29 15:16:12 2017 +1000)

#### 2.0.0.beta.2 (2017-04-29)
* 1dfef17 - Cleaned up migrations and ensured migrations run on postgresql. (Beth Skurrie, Fri Apr 28 21:24:20 2017 +1000)

#### 2.0.0.beta.1 (2017-04-28)
* 049bc5c - Added tooltip to verification date to show provider version. (Beth Skurrie, Fri Apr 28 10:05:13 2017 +1000)
* 4287c99 - Add tooltip text to last verified date when pact has changed since last verification. (Beth Skurrie, Fri Apr 28 09:02:59 2017 +1000)
* 7351ec8 - Add restrictions for all gem versions in gemspec. Fix formatting in haml file. (Beth Skurrie, Thu Apr 27 19:55:04 2017 +1000)
* a836b56 - Add last verified date for each pact to landing page of application UI. (Beth Skurrie, Tue Apr 25 17:03:06 2017 +1000)
* c7589c9 - Use latest ruby-2.3.4 for development. (Tan Le, Mon Apr 24 23:05:27 2017 +1000)
* 46b87f9 - Use latest ruby patches for CI. (Tan Le, Mon Apr 24 23:00:12 2017 +1000)
* 7c17c62 - Required at least ruby-2.2.0 as we move along ruby release schedule. (Tan Le, Mon Apr 24 22:54:52 2017 +1000)
* 66a2f3b - Added pb:publish-verification HAL link to pact resource. (Beth Skurrie, Fri Apr 21 16:09:55 2017 +1000)
* f2110ac - Replacing versionomy with semver2 for parsing version numbers according to semver 2.0.0 (http://semver.org) (Danilo Sato, Thu Apr 20 11:48:49 2017 -0400)
* 1f6045a - Added DEVELOPER_DOCUMENTATION.md with information about the tables and views. (Beth Skurrie, Tue Apr 18 11:35:39 2017 +1000)
* 77eaf7b - Added pb:latest-verifications link to version resource. (Beth Skurrie, Tue Apr 11 16:25:45 2017 +1000)
* aaf44d9 - Added endpoint to view the latest verifications for a given consumer version. (Beth Skurrie, Tue Apr 11 11:16:03 2017 +1000)

#### 1.18.0 (2017-05-09)
* 397060b - Display application versions in reverse order in the Versions resource. (Beth Skurrie, Tue May 9 13:59:54 2017 +1000)
* 251c878 - Allow application versions to be ordered by creation date where no consistent orderable object can be extracted from the consumer application version. (Beth Skurrie, Tue May 9 13:22:36 2017 +1000)
* 68bb6d9 - Execute webhooks using sucker punch. (Beth Skurrie, Mon May 8 10:32:45 2017 +1000)

#### 1.17.2 (2017-05-04)
* b8f45e1 - fix issue with pact document link not displaying #94 (Matt Fellows, Wed May 3 11:23:09 2017 +1000)

#### 1.17.1 (2017-05-02)
* 7576bc2 - Fix 500 error in webhooks endpoint. (Beth Skurrie, Tue May 2 14:35:06 2017 +1000)
* 7351ec8 - Add restrictions for all gem versions in gemspec. Fix formatting in haml file. (Beth Skurrie, Thu Apr 27 19:55:04 2017 +1000)

#### 1.17.0 (2017-04-26)
* 5cbb9da - Added pb:publish-pact to HAL index (Beth Skurrie, Wed Apr 26 08:39:15 2017 +1000)
* 36842d1 - Set database connection timezone to UTC in example config.ru (Beth Skurrie, Tue Apr 25 16:18:58 2017 +1000)
* c7589c9 - Use latest ruby-2.3.4 for development. (Tan Le, Mon Apr 24 23:05:27 2017 +1000)
* 46b87f9 - Use latest ruby patches for CI. (Tan Le, Mon Apr 24 23:00:12 2017 +1000)
* 7c17c62 - Required at least ruby-2.2.0 as we move along ruby release schedule. (Tan Le, Mon Apr 24 22:54:52 2017 +1000)

#### 1.16.0 (2017-04-10)
* 990575f - Added HTML content type for request to get a specific version of a pact. As per request in https://github.com/pact-foundation/pact_broker/issues/82 (Beth Skurrie, Mon Apr 10 15:34:28 2017 +1000)
* b47b8d8 - Use /versions rather than /version in test endpoint. Singular will be deprecated. (Beth Skurrie, Fri Apr 7 16:03:19 2017 +1000)
* dd4daee - Removed version restriction for pact_broker gem in the example Gemfile. This will avoid a repetition of the twisted dependencies fixed by https://github.com/pact-foundation/pact_broker/pull/84 (Beth Skurrie, Tue Apr 4 09:53:39 2017 +1000)
* e447b3f - Updated sqlite database. (Beth Skurrie, Mon Apr 3 08:25:41 2017 +1000)
* 149efc0 - Update REAME to reflect 2.4 support. (Tan Le, Fri Mar 31 21:42:47 2017 +1100)

#### 1.15.0 (2017-03-28)
* 588c33e - Adds versions decorator spec (Ivan Vojinovic, Wed Feb 22 00:00:46 2017 -0500)
* c4a7daf - Adds pacticipant versions endpoint (Ivan Vojinovic, Tue Feb 21 21:15:39 2017 -0500)
* 06bcbc8 - Added ruby 2.4.0 to travis.yml (Beth Skurrie, Tue Mar 28 19:09:06 2017 +1100)
* 6d7653b - Bump pact_broker version to 1.14.0 to resolve twisted dependencies. (Tan Le, Mon Mar 27 22:36:22 2017 +1100)
* c8eeab4 - Remove trailblazer dependency. (Tan Le, Mon Mar 27 21:56:43 2017 +1100)
* e62c5ec - Added copyright year and owner. (Beth Skurrie, Fri Mar 24 10:39:39 2017 +1100)
* 5007f5b - Bump trailblazer version due to roar compatibility. (Tan Le, Mon Feb 20 10:22:41 2017 +1100)
* 4865948 - Bump reform and friends versions. (Tan Le, Wed Feb 15 09:16:29 2017 +1100)
* 0920e45 - Add hosted pact broker to usage section in README (Matt Fellows, Sat Feb 4 11:28:36 2017 +1100)

#### 1.14.0 (2017-01-30)
* 83ac7a5 - Adds ability to delete tags (Ivan Vojinovic, Fri Jan 27 15:19:51 2017 -0500)

#### 1.13.0 (2017-01-18)
* b9b67b3 - Adds the spec for pact versions endpoint, and corrects the file name for the provider pacts spec (Ivan Vojinovic, Tue Jan 17 23:43:03 2017 -0500)
* ace427e - Adds the spec for pact versions endpoint, and corrects the file name for the provider pacts spec (Ivan Vojinovic, Tue Jan 17 23:36:33 2017 -0500)
* 8b14b35 - Adds endpoint for (and fixes) pact_versions (Ivan Vojinovic, Mon Jan 16 21:12:02 2017 -0500)

#### 1.12.0 (2016-12-09)
* 67779ac - add pb:latest-provider-pacts-with-tag to index.rb (Olga Vasylchenko, Thu Dec 8 16:02:19 2016 +0100)
* cdfa17b - upgrade default sqlite db to current migration level (Bo Daley, Wed Nov 30 14:37:54 2016 -0500)

#### 1.11.2 (2016-11-25)
* 43f2373 - Added require to hopefully fix broken build. https://travis-ci.org/pact-foundation/pact_broker/jobs/174397806 (Bethany Skurrie, Thu Nov 24 07:47:07 2016 +1100)
* f747e09 - Removed ruby 2.1 build as it is failing (Beth Skurrie, Wed Nov 9 13:42:08 2016 +1100)
* 2dd77a5 - Added extra pact version to example database so that the diff feature could be explored. (Beth, Wed Nov 9 10:07:33 2016 +1100)
* 5c04c59 - Updated trailblazer gem to ~>0.3.0 and fixed pact diff spec. (Beth, Wed Nov 9 10:05:53 2016 +1100)
* 8102ac9 - Use respond_to?(:acts_like_time?) instead of acts_like?(:time) as it blows up (Beth, Sun Nov 6 12:00:30 2016 +1100)

#### 1.11.1 (2016-10-13)
* 14381ac - Fix issue #59 Error when executing web hook with body. (Beth Skurrie, Thu Oct 13 12:50:17 2016 +1100)

#### 1.11.0 (2016-08-13)
* 18ffc4a - Add conflict guards to pact merger (Steve Pletcher, Fri Aug 5 12:31:30 2016 -0400)

#### 1.10.0 (2016-08-01)
* efdde13 - Add ability to merge pacts via PATCH requests (Steve Pletcher, Thu Jul 28 16:29:22 2016 -0400)

#### 1.9.3 (2016-06-27)
* f57db36 - Clarify that pact_broker will only work with ruby >= 2.0 (Sergei Matheson, Mon Jun 27 11:06:40 2016 +1000)
* a1742b8 - Correct release instructions (Sergei Matheson, Mon Jun 27 11:03:03 2016 +1000)
* 7d0f362 - Update default dev ruby version to 2.3.1 (Sergei Matheson, Mon Jun 27 11:00:40 2016 +1000)
* 42dc7fe - Update to ruby 2.3.1 in travis (Sergei Matheson, Tue May 3 10:46:46 2016 +1000)
* df9a910 - Fix for Webmock 2.0.0 behaviour change. (Sergei Matheson, Fri Apr 29 13:19:57 2016 +1000)

#### 1.9.2 (2016-04-29)
* 6d4ce4f - Update default dev ruby version to 2.3.0 (Sergei Matheson, Fri Apr 29 11:39:59 2016 +1000)
* 039fce9 - Add release instructions (Sergei Matheson, Fri Apr 29 10:42:17 2016 +1000)
* d48a1fa - Append `charset=utf-8` in json error response (Taiki Ono, Tue Mar 15 21:11:59 2016 +0900)
* 7f34940 - Remove unused variable (Taiki Ono, Tue Mar 15 21:06:23 2016 +0900)
* e932c28 - Append `charset=utf-8` to `Content-Type` header (Taiki Ono, Tue Mar 15 17:54:48 2016 +0900)
* 6252c1c - Does not change YAML::ENGINE.yamler (Taiki Ono, Sun Mar 13 22:03:41 2016 +0900)
* 9f02474 - Update Travis CI setting with new Rubies (Taiki Ono, Sun Mar 13 21:19:17 2016 +0900)
* 5a506dc - Belatedly, updated changelog (Sergei Matheson, Fri Feb 26 09:30:46 2016 +1100)

#### 1.9.1 (2016-02-26)
* e6e6d49 - Release version 1.9.1 (Sergei Matheson, Fri Feb 26 09:26:52 2016 +1100)
* 5ea7607 - Merge pull request #44 from sigerber/master (Beth Skurrie, Thu Feb 25 14:39:17 2016 +1100)
* ade2599 - Fix performance of groupify (Horia Musat and Simon Gerber, Wed Feb 24 14:50:39 2016 +1100)
* 38869ad - Return a 409 when there is a potential duplicate pacticipant name when publishing a pact. (Beth, Thu Nov 5 17:43:32 2015 +1100)
* 2991441 - Merge pull request #42 from bethesque/issue-41 (Beth Skurrie, Fri Oct 23 15:52:39 2015 +1100)
* 933981c - Now supports HTTPS webhooks (Warner Godfrey, Fri Oct 23 14:48:28 2015 +1100)
* 2123ff1 - Merge pull request #40 from elgalu/travis-badge (Beth Skurrie, Thu Oct 15 06:40:09 2015 +1100)
* 88cea3f - Add TravisCI badge in README.md (Leo Gallucci, Wed Oct 14 17:02:52 2015 +0200)
* b54c5c6 - Merge pull request #38 from gitter-badger/gitter-badge (Beth Skurrie, Tue Sep 29 15:37:27 2015 +1000)
* 42e9bc2 - Add Gitter badge (The Gitter Badger, Tue Sep 29 04:51:17 2015 +0000)
* 711ac85 - Merge pull request #37 from elgalu/ruby-2.1.3 (Beth Skurrie, Fri Sep 18 06:42:47 2015 +1000)
* 40ddb97 - Add ruby 2.1.3 and set as default (Leo Gallucci, Thu Sep 17 16:19:09 2015 +0200)
* a1fa248 - Updated example with postgres details (Beth, Thu Sep 17 09:25:09 2015 +1000)
* 383d137 - Create LICENSE.txt (Beth Skurrie, Mon Aug 24 06:29:50 2015 +1000)

#### 1.9.0 (2015-08-19)

* eda171e - Allow pact broker API to be run using Rack map at an arbitrary path. e.g. "/foo/pacts". Note, this does not work for the UI. (Beth, Wed Aug 19 08:44:21 2015 +1000)

#### 1.9.0.rc1 (2015-07-19)

* c855a2c - Support case insensitive resource names (Beth Skurrie, Sun Jul 19 17:28:55 2015 +1000)
* 7ea3e61 - Update pact_broker.gemspec (Beth Skurrie, Tue Jul 14 09:02:30 2015 +1000)
* f299cfd - Added logging for publishing and deleting pacts (Beth Skurrie, Wed Jul 8 16:00:58 2015 +1000)
* 67f0edb - Log error when contract cannot be parsed to a Pact (Beth Skurrie, Wed Jul 8 15:54:29 2015 +1000)
* 57caf63 - Double ensure that tables are created with UTF-8 encoding https://github.com/pact-foundation/pact_broker/issues/24 (Beth Skurrie, Fri Jul 3 15:46:46 2015 +1000)

#### 1.8.1 (2015-06-30)

* d0d466d - Avoid making a query for tags for each pact shown on the Pacts page (Beth Skurrie, Tue Jun 30 06:42:09 2015 +1000)

#### 1.8.0 (2015-05-28)

* 6c40e9c - Added ability to specify a tag when retrieving pacts for a given provider (Beth Skurrie, Thu May 28 09:03:46 2015 +1000)
* dda9f1d - Added endpoint to retrieve latest pacts by provider (Beth Skurrie, Sun May 10 21:28:33 2015 +1000)
* 21e676a - Pact broker example for heroku with basic auth (BrunoChauvet, Sat Apr 25 13:04:54 2015 +1000)

#### 1.7.0 (2015-03-20)

* a26402c - Allow configuration of version parsing. (Beth Skurrie, Tue Apr 14 09:39:05 2015 +1000)

#### 1.6.0 (2015-03-20)

* e20e657 - Added support for JSON contracts that are not in the Pact format (e.g. top level is an array) (Beth Skurrie, Fri Mar 20 19:12:46 2015 +1100)

#### 1.5.0 (2015-02-20)

* b848ce3 - Added healthcheck endpoint for database dependency. /diagnostic/status/dependencies (Beth, Fri Feb 20 09:41:16 2015 +1100)
* 56ea4a6 - Added heartbeat endpoint for monitoring. /diagnostic/status/heartbeat (Beth, Fri Feb 20 08:49:51 2015 +1100)
* dbdb4fb - Upgraded webmachine gem to 1.3.1 (Beth, Wed Feb 11 21:49:55 2015 +1100)
* 111f088 - Added validation to ensure that the encoding for the database connection is set to UTF8. This is required to ensure the pact_version_content_sha foreign key works. (Beth, Wed Feb 11 20:03:34 2015 +1100)

#### 1.4.0 (2015-01-20)

* d740fb0 - Removed pact-versions rel from pact resource. Pact versions resource is not implemented yet. (Beth, Tue Jan 20 09:20:52 2015 +1100)
* bd6e63e - Handle case where there is no previous distinct version when displaying diff (Beth, Tue Jan 20 09:17:21 2015 +1100)
* d032ce1 - Changed pact icon on Pacts page to look more like a pact. (Beth, Wed Dec 24 09:58:35 2014 +1100)
* dbf67aa - Added endpoint for previous distinct pact version. (Beth, Mon Dec 22 14:08:07 2014 +1100)
* bde72f9 - Added migration to change pacts table to UTF8 (Beth, Mon Dec 22 11:45:09 2014 +1100)
* 8f587b7 - Modified pact HAL rels. (Beth, Mon Dec 22 11:41:10 2014 +1100)
* b813c0d - Renamed Relationships to Pacts. It was confusing. (Beth, Mon Dec 22 10:25:27 2014 +1100)
* 00d81aa - Changed diff resource to text/plain, added dates (Beth, Sun Dec 14 17:05:18 2014 +1100)
* 8f05772 - Set timezone to utc for test db connection (Beth, Sun Dec 14 17:04:16 2014 +1100)
* 407fa74 - Added link from HAL browser to home (Beth, Sat Dec 13 19:54:53 2014 +1100)
* a62faa9 - Adding missing docs (Beth, Sat Dec 13 19:51:36 2014 +1100)
* ec04e77 - Added HAL link to diff with previous distinct version (Beth, Fri Dec 12 08:31:12 2014 +1100)
* fe5f1d6 - Added endpoint to see the diff between a pact and the previous distinct version. (Beth, Thu Dec 11 17:35:22 2014 +1100)
* f802641 - Added version endpoint. (Beth, Wed Dec 10 13:06:13 2014 +1100)
* 715f49d - Force documentation window in HAL browser to be longer. This used to display correctly, but has somehow become quite short. Don't know what changed. (Beth, Tue Dec 9 18:47:53 2014 +1100)
* 25e612b - Removed curie from self links (Beth, Wed Dec 3 21:14:23 2014 +1100)
* 5cc922e - Added script to publish test pact. (Beth, Wed Dec 3 20:26:31 2014 +1100)
* f468b2c - Changed Padrino to log to stdout. :null creates a StringIO, don't want to hog memory. (Beth, Wed Dec 3 20:25:05 2014 +1100)

#### 1.3.2.rc1 (2014-12-03)

* a2413f4 - Stop Padrino trying to create a log file in the gem directory https://github.com/pact-foundation/pact_broker/issues/13 (Beth, Wed Dec 3 13:16:06 2014 +1100)
* abf9459 - Added DELETE endpoint for pact resource (Beth, Wed Nov 19 17:45:34 2014 +1100)
* 1d01937 - Set default encoding to utf-8 in example app. This is required for the sha foreign key to work between the pact table and the pact_version_content table. (Beth, Tue Nov 18 22:35:51 2014 +1100)
* 9e3401e - Save all the space! Reuse the same pact_version_content when one with the same sha1 already exists in the database. (Beth, Tue Nov 18 20:27:59 2014 +1100)
* 84ab8ad - Creating example pact_broker_database.sqlite3 with the Zoo App/Animal Service pact (Beth, Tue Nov 18 17:30:25 2014 +1100)
* d767b0d - Fixed query for all pacts when pact has more than one tag (Beth, Mon Nov 17 20:44:01 2014 +1100)
* 21563c6 - Changed date to use day name and month name instead of numbers (Beth, Wed Nov 12 16:19:19 2014 +1100)
* 7766b77 - Added count to relationships page. (Beth, Mon Nov 3 11:06:05 2014 +1100)

#### 1.3.1 (2014-10-23)

* e61b40e - Added Travis configuration. (Beth, Fri Oct 17 16:32:26 2014 +1100)
* b320fe4 - Fixed pact publish validation for ruby 1.9.3 (Beth, Fri Oct 17 16:31:41 2014 +1100)
* b9b4d2b - Added validation to ensure that the participant names in the path match the participant names in the pact. (Beth, Thu Oct 16 20:21:10 2014 +1100)

#### 1.3.0 (2014-10-14)

* ed08811 - Converted raw SQL create view statements to Sequel so they will run on Postgres (Beth, Sat Oct 11 22:07:37 2014 +1100)
* 457edf4 - Added syntax highlighting to JSON in autogenerated HTML docs. (Beth, Wed Sep 24 22:12:14 2014 +1000)

#### 1.2.0 (2014-09-22)

* 0ccde50 - Made webhook creation code more Webmachiney. (Beth, Tue Sep 16 10:07:56 2014 +1000)
* 4c628e5 - Using localtime to display dates. (Beth, Fri Aug 29 13:32:20 2014 +1000)
* 7d99c51 - Fixed HAL Browser link - page title was stopping it being clickable (Beth, Fri Sep 5 16:41:03 2014 +1000)
* 8ba3be0 - Updating spec task for latest rspec (Beth, Fri Sep 5 16:40:10 2014 +1000)
* fcc25eb - Updated pact gem (Beth, Tue Aug 26 18:45:31 2014 +1000)
* 5d0d3dc - Added pact versions link to the pact response (Beth, Tue Aug 26 07:54:26 2014 +1000)
* 16971ff - Added method to find distinct pacts between a consumer and provider (Beth, Tue Aug 26 07:41:54 2014 +1000)
* 4798c09 - Added pact versions endpoint. (Beth, Mon Aug 25 22:23:48 2014 +1000)
* e1f8c97 - Changed 'Date published' to display pact.updated_at date instead of created_at date (Beth, Mon Aug 25 07:37:58 20
* 39eac31 - Fixed pact-webhooks rel title (Beth, Sun Aug 24 17:54:05 2014 +1000)
* f6fc9f7 - Added latest-pact rel to pact representation (Beth, Sun Aug 24 17:51:08 2014 +1000)
* 08b088c - Added method to pacticipant_service to find potentially duplicated pacticipants (Beth, Sat Aug 23 08:32:34 2014 +
* 24e8d5d - Adding support for creating a pacticipant through the API (as distinct from it being auto created by publishing a
* dc4d4aa - Set DB timezone to UTC. (Beth, Thu Aug 21 17:30:41 2014 +1000)
* 19693fa - Added pact metadata to HTML view (Beth, Thu Aug 21 17:30:23 2014 +1000)

#### 1.1.0 (2014-08-21)

* d25395b - Fixed pacts failing to publish because of too deeply nested JSON (Beth, Tue Aug 19 11:13:02 2014 +1000)
* 9288c98 - Saving password in Base64 just so it is not plain text. WIP (Beth, Tue Aug 19 09:14:53 2014 +1000)
* 6a40151 - Added username and password to webhook request (Beth, Mon Aug 18 22:02:48 2014 +1000)
* 6eb0d70 - Added mouseover for relationship paths (Beth, Fri Aug 15 15:38:56 2014 +1000)
* 8e916fc - Added clickable relationship links (Beth, Fri Aug 15 11:37:57 2014 +1000)
* 7fc6418 - Added webhook HAL documentation. (Beth, Tue Aug 12 17:17:08 2014 +1000)
* 434fbe8 - Added useful rels to help navigate between webhook resources. (Beth, Tue Aug 12 09:14:08 2014 +1000)
* 959675b - Adding description to webhooks link (Beth, Mon Aug 11 21:46:39 2014 +1000)
* 9cbf2b1 - Added webhook test execution endpoint. (Beth, Mon Aug 11 21:37:47 2014 +1000)
* 6bdfd16 - Webhooks belonging to a pacticipant will be deleted when the pacticipant is deleted. (Beth, Mon Aug 11 14:16:50 2014 +1000)
* 27572e2 - WIP - ensuring webhook executes when a pact version is overridden and changed. (Beth, Fri Aug 8 16:59:48 2014 +1000)
* 2469ad5 - Adding webhook DELETE (Beth, Fri Aug 8 16:45:48 2014 +1000)
* 7ae9b59 - Adding code to execte webhook and to detect when pact content has changed (Beth, Fri Aug 8 10:13:16 2014 +1000)
* c8289fb - Adding /webhooks resource (Beth, Thu Aug 7 16:57:27 2014 +1000)
* 2d818ee - Added endpoint to retrieve webhook by UUID (Beth, Thu Aug 7 14:35:04 2014 +1000)
* 25c3866 - Completed web hooks resource. (Beth, Wed Aug 6 11:38:39 2014 +1000)
* a59e46e - Started work on webhooks (Beth, Sat Aug 2 18:12:16 2014 +1000)
* 56d9ae5 - Return 400 error for pacts with invalid JSON (Beth, Sat Aug 2 07:08:39 2014 +1000)
* 884aa06 - Added links from relationship page to group. (Beth, Thu Jul 31 20:05:55 2014 +1000)
* 642570e - Adding group UI endpoint. (Beth, Thu Jul 31 17:36:37 2014 +1000)
* 3609028 - Adding a group resource (Beth, Mon Jul 28 09:11:46 2014 +1000)
* 437df9e - Added created_at and updated_at timestamps to all objects. (Beth, Fri Jul 25 16:53:46 2014 +1000)
* 594f160 - Turning exception showing on (Beth, Fri Jul 25 08:59:57 2014 +1000)
* 7250a51 - Updated to pact 1.3.0 (Beth, Thu Jul 24 12:13:38 2014 +1000)
* 9824247 - Implemented DELETE for pacticipant resource (Beth, Tue Jun 10 17:32:26 2014 +1000)
* 1c65600 - Swapped links and properties order in the HAL browser, because the documents are large, and scrolling to the bottom of the page to click around is annoying. (Beth, Fri Jun 6 10:19:47 2014 +1000)

#### 1.0.0 (2014-06-06)

* ed25adb - Sorting relationships by consumer name, then provider name. (Beth, Wed May 21 15:13:39 2014 +1000)
* 7aae530 - Releasing version 1.0.0.alpha3 (Beth, Mon May 19 15:44:33 2014 +1000)
* 53e24cb - Increased json_content size from text to mediumtext (16MB) (Beth, Mon May 19 15:43:32 2014 +1000)
* 1f65546 - Releasing 1.0.0.alpha2 (Beth, Mon May 19 12:49:42 2014 +1000)
* 3714ab5 - Adding network graph spike files (Beth, Sat May 17 21:12:04 2014 +1000)
* 73e2b81 - Implemented finding latest pact by tag (Beth, Sat May 17 17:56:58 2014 +1000)
* bfa62cc - Changed /pact to /pacts because it is more RESTy (Beth, Sat May 17 12:22:55 2014 +1000)
* 91c8fab - Releasing 1.0.0.alpha1 (Beth, Fri May 9 15:21:13 2014 +1000)
* f497f13 - Made HtmlPactRenderer configurable in case shokkenki want to use the PactBroker ;) (Beth, Fri May 9 14:20:38 2014 +1000)
* 5343019 - Added Relationship UI (Beth, Fri May 9 12:23:30 2014 +1000)
* f7270a6 - Added HTML rendering of latest pact. Added /relationships CSV endpoint. (Beth, Thu May 8 16:17:52 2014 +1000)
* 264e16b - Created nice interface for making a pact_broker instance (Beth, Sat Apr 26 16:43:07 2014 +1000)
* 8001792 - Added HAL browser (Beth, Wed Apr 23 13:31:25 2014 +1000)
* 8c94d1f - Creating example app (Beth, Wed Apr 23 13:06:40 2014 +1000)

#### 0.0.10 (2014-06-06)

  * 24daeea - Added task to delete pacticipant (bethesque Tue May 20 11:59:10 2014 +1000)
  * 53e24cb - Increased json_content size from text to mediumtext (16MB) (bethesque Mon May 19 15:43:32 2014 +1000)
  * 73e2b81 - Implemented finding latest pact by tag (bethesque Sat May 17 17:56:58 2014 +1000)
  * bfa62cc - Changed /pact to /pacts because it is more RESTy (bethesque Sat May 17 12:22:55 2014 +1000)
  * a7a8e0d - Upgraded padrino (bethesque Sat May 17 12:20:57 2014 +1000)
  * 94c7c38 - Setting gem versions in gemspec (bethesque Fri May 9 15:22:37 2014 +1000)
  * f497f13 - Made HtmlPactRenderer configurable in case shokkenki want to use the PactBroker ;) (bethesque Fri May 9 14:20:38 2014 +1000)
  * 1d35da4 - Added sort to relationships list (bethesque Fri May 9 13:56:55 2014 +1000)
  * 000f8a6 - Added HAL Browser link (bethesque Fri May 9 13:39:56 2014 +1000)
  * 85e0a1d - Redirecting index to relationships page (bethesque Fri May 9 13:15:55 2014 +1000)
  * 5343019 - Added Relationship UI (bethesque Fri May 9 12:23:30 2014 +1000)
  * f7270a6 - Added HTML rendering of latest pact. (bethesque Thu May 8 16:17:52 2014 +1000)

#### 0.0.10 (2014-03-24)

* 7aee2ae - Implemented version tagging (bethesque 2 days ago)
* cc78f92 - Added 'latest' pact url to pact representation in the 'latest pacts' response (bethesque 2 days ago)

#### 0.0.9 (2014-02-27)

* d07f4b7 - Using default gem publish tasks (bethesque 4 weeks ago)
* d60b7ee - Comment (bethesque 7 weeks ago)
* 836347c - Using local pacts (bethesque 7 weeks ago)
* a2cb2bb - Fixed bug querying mysql DB, rather than sqlite (bethesque 7 weeks ago)
* 9d5f83b - Using the to_json options to pass in the base_url instead of the nasty hack. (bethesque 4 months ago)
* adb6148 - Changed 'last' to 'latest' (bethesque 4 months ago)

#### 0.0.8 (2013-11-18)

* 6022baa - Changed name to title in list pacticipants response (bethesque 7 hours ago)
* 13fde52 - Moving resources module under the Api module. (bethesque 8 hours ago)
* f52c572 - Added HAL index (bethesque 8 hours ago)

#### 0.0.7 (2013-11-15)

* 7984d86 - Added title to each item in the pacts/latest links array (bethesque 83 seconds ago)

#### 0.0.6 (2013-11-15)

* 021faae - Refactoring resources to DRY out code (bethesque 18 hours ago)
* bab0367 - Cleaning up the base_url setting hack. (bethesque 19 hours ago)
* f6df613 - Renamed representors to decorators (bethesque 19 hours ago)
* 3e89c20 - Created BaseDecorator (bethesque 19 hours ago)
* e5c3f88 - Changing from representors to decorators (bethesque 19 hours ago)
* b2eeb6f - Added back resource_exists? implementation in pacticipant resource - accidental deletion. (bethesque 19 hours ago)
* 1962a05 - Ever so slightly less hacky way of handling PATCH (bethesque 21 hours ago)
* 587e9c1 - First go at trying to use a dynamic base URL - to be continued (bethesque 2 days ago)
* ab9c185 - Including URLs for the dynamically calculated latest pact, not the hard link to the latest pact. (bethesque 2 days ago)
* 5621e41 - Beginning change from Roar Representor to Decoractor. Updating to new 'latest pact' URL (bethesque 2 days ago)
* d1bd995 - Adding missing PactBroker::Logging require (bethesque 2 days ago)

#### 0.0.5 (2013-11-13)

* 2cf987c - Added data migration to script which adds order column (bethesque 56 minutes ago)
* 9c709a9 - Changing queries to use new order column. (bethesque 61 minutes ago)
* 173f231 - Renaming var (bethesque 65 minutes ago)
* f9be93d - Renamed SortVersions to OrderVersions (bethesque 66 minutes ago)
* ca6e479 - Added SortVersions as an after version save hook (bethesque 69 minutes ago)
* 23cd1a3 - Adding order column to version table (bethesque 11 hours ago)
* c504e5f - Fixing application/json+hal to application/hal+json (bethesque 2 days ago)
* 1d24b9b - Removing old sinatra API (bethesque 2 days ago)
* fd1832c - WIP. Converting to use Webmachine (bethesque 2 days ago)
* 0b096a4 - Redoing the the URLs yet again (bethesque 3 days ago)
* 0934d89 - Implementing list latest pacts (bethesque 3 days ago)
* ed2d354 - Changed one_to_one associations to many_to_one (bethesque 4 days ago)
* 28de0ea - WIP implementing pacts/latest. (bethesque 6 days ago)
* 1cd36e6 - Changing to new /pacts/latest URL format (bethesque 6 days ago)
* 54f8fc3 - Writing underlying code to find the latest pact for each consumer/provider pair. (bethesque 6 days ago)
