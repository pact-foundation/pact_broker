# Provider pacts for verification

Path: `/pacts/provider/{provider}/for-verification`

Allowed methods: `POST`

Content type: `application/hal+json`

Returns a deduplicated list of pacts to be verified by the specified provider.

### Body

Example: This data structure represents the way a user might specify "I want to verify the latest 'master' pact, all 'prod' pacts, and when I publish the verification results, I'm going to tag the provider version with 'master'"

    {
      "consumerVersionSelectors": [
        {
          "tag": "master",
          "latest": true
        },{
          "tag": "prod"
        }
      ],
      "providerVersionTags": ["master"],
      "includePendingStatus": true,
      "includeWipPactsSince": "2020-01-01"
    }


`consumerVersionSelectors.tag`: the tag name(s) of the consumer versions to get the pacts for.

`consumerVersionSelectors.fallbackTag`: the name of the tag to fallback to if the specified `tag` does not exist. This is useful when the consumer and provider use matching branch names to coordinate the development of new features.

`consumerVersionSelectors.latest`: true. If the latest flag is omitted, *all* the pacts with the specified tag will be returned. (This might seem a bit weird, but it's done this way to match the syntax used for the matrix query params. See https://docs.pact.io/selectors)

`consumerVersionSelectors.consumer`: allows a selector to only be applied to a certain consumer. This is used when there is an API that has multiple consumers, one of which is a deployed service, and one of which is a mobile consumer. The deployed service only needs the latest production pact verified, where as the mobile consumer may want all the production pacts verified.

`providerVersionTags`: the tag name(s) for the provider application version that will be published with the verification results. This is used by the Broker to determine whether or not a particular pact is in pending state or not. This parameter can be specified multiple times.

`includePendingStatus`: true|false (default false). When true, a pending boolean will be added to the verificationProperties in the response, and an extra message will appear in the notices array to indicate why this pact is/is not in pending state. This will allow your code to handle the response based on only what is present in the response, and not have to do ifs based on the user's options together with the response. As requested in the "pacts for verification" issue, please print out these messages in the tests if possible. If not possible, perhaps create a separate task which will list the pact URLs and messages for debugging purposes.

`includeWipPactsSince`: Date string. The date from which to include the "work in progress" pacts. See https://docs.pact.io/wip for more information on work in progress pacts.

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

