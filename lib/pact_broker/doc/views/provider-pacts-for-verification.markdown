# Provider pacts for verification

Path: `/pacts/provider/{provider}/for-verification`

Allowed methods: `POST`

Content type: `application/hal+json`

Returns a deduplicated list of pacts to be verified by the specified provider.

### Body

Example: This data structure represents the way a user might specify "I want to verify the latest 'main' pact, all the pacts for the consumer versions that are currently deployed, and when I publish the verification results, the provider version will be be on the "main" branch.

    {
      "consumerVersionSelectors": [
        {
          "branch": "main"
        },
        {
          "deployed": true
        }
      ],
      "providerVersionBranch": "main",
      "includePendingStatus": true,
      "includeWipPactsSince": "2020-01-01"
    }

`consumerVersionSelectors.mainBranch`: if the key is specified, can only be set to `true`. Return the pacts for the configured `mainBranch` of each consumer. Use of this selector requires that the consumer has configured the `mainBranch` property, and has set a branch name when publishing the pacts.

`consumerVersionSelectors.branch`: the branch name of the consumer versions to get the pacts for. Use of this selector requires that the consumer has configured a branch name when publishing the pacts.

`consumerVersionSelectors.matchingBranch`: if the key is specified, can only be set to `true`. When true, returns the latest pact for any branch with the same name as the specified `providerVersionBranch`.

`consumerVersionSelectors.fallbackBranch`: the name of the branch to fallback to if the specified `branch` does not exist. Use of this property is discouraged as it may allow a pact to pass on a feature branch while breaking backwards compatibility with the main branch, which is generally not desired. It is better to use two separate consumer version selectors, one with the main branch name, and one with the feature branch name, rather than use this property.

`consumerVersionSelectors.deployed`: if the key is specified, can only be set to `true`. Returns the pacts for all versions of the consumer that are currently deployed to any environment. Use of this selector requires that the deployment of the consumer application is recorded in the Pact Broker using the `pact-broker record-deployment` CLI.

`consumerVersionSelectors.released`: if the key is specified, can only be set to `true`. Returns the pacts for all versions of the consumer that are released and currently supported in any environment. Use of this selector requires that the deployment of the consumer application is recorded in the Pact Broker using the `pact-broker record-release` CLI.

`consumerVersionSelectors.deployedOrReleased`: if the key is specified, can only be set to `true`. Returns the pacts for all versions of the consumer that are currently deployed or released and currently supported in any environment. Use of this selector requires that the deployment of the consumer application is recorded in the Pact Broker using the `pact-broker record-deployment` or `record-release` CLI.

`consumerVersionSelectors.environment`: the name of the environment containing the consumer versions for which to return the pacts. Used to further qualify `{ "deployed": true }` or `{ "released": true }`. Normally, this would not be needed, as it is recommended to verify the pacts for all currently deployed/currently supported released versions.

`consumerVersionSelectors.latest`: true. Used in conjuction with the tag property. If a tag is specified, and latest is true, then the latest pact for each of the consumers with that tag will be returned. If a tag is specified and the latest flag is not set to true, all the pacts with the specified tag will be returned. (This might seem a bit weird, but it's done this way to match the syntax used for the matrix query params. See https://docs.pact.io/selectors).

`consumerVersionSelectors.consumer`: allows a selector to only be applied to a certain consumer.

`consumerVersionSelectors.tag`: the tag name(s) of the consumer versions to get the pacts for. *This field is still supported but it is recommended to use the `branch` in preference now.*

`consumerVersionSelectors.fallbackTag`: the name of the tag to fallback to if the specified `tag` does not exist. This is useful when the consumer and provider use matching branch names to coordinate the development of new features. *This field is still supported but it is recommended to use the `fallbackBranch` in preference now.*

`providerVersionBranch`: the repository branch name for the provider application version that will be published with the verification results. This is used by the Broker to determine whether or not a particular pact is in pending state or not.

`includePendingStatus`: true|false (default false). When true, a pending boolean will be added to the verificationProperties in the response, and an extra message will appear in the notices array to indicate why this pact is/is not in pending state. This will allow your code to handle the response based on only what is present in the response, and not have to do ifs based on the user's options together with the response. As requested in the "pacts for verification" issue, please print out these messages in the tests if possible. If not possible, perhaps create a separate task which will list the pact URLs and messages for debugging purposes.

`includeWipPactsSince`: Date string. The date from which to include the "work in progress" pacts. See https://docs.pact.io/wip for more information on work in progress pacts.

`providerVersionTags`: the tag name(s) for the provider application version that will be published with the verification results. This is used by the Broker to determine whether or not a particular pact is in pending state or not. This parameter can be specified multiple times. *This field is still supported but it is recommended to use the `providerVersionBranch` in preference now.*

### Response body

`pending` flag and  the "pending reason" notice will only be included if `includePendingStatus` is set to true.


    {
      "_embedded": {
        "pacts": [
          {
            "verificationProperties": {
              "notices": [
                {
                  "text": "This pact is being verified because it is the pact for the latest version of Foo tagged with 'dev'",
                  "when": "before_verification"
                }
              ],
              "pending": false
            },
            "_links": {
              "self": {
                "href": "http://localhost:9292/pacts/provider/Bar/consumer/Foo/pact-version/0e3369199f4008231946e0245474537443ccda2a",
                "name": "Pact between Foo (v1.0.0) and Bar"
              }
            }
          }
        ]
      },
      "_links": {
        "self": {
          "href": "http://localhost:9292/pacts/provider/Bar/for-verification",
          "title": "Pacts to be verified"
        }
      }
    }

