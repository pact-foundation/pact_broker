# Publish Contracts

Allowed methods: `POST`

Path: `/contracts/publish`

Index relation: `pb:publish-contracts`

Supported from: `v2.86.0`

This is the preferred endpoint with which to publish contracts (previously, contracts were published using multiple calls to different endpoints to create the tag and contract resources). To detect whether this endpoint exists in a particular version of the Pact Broker, make a request to the index resource, and locate the `pb:publish-contracts` relation. Do a `POST` to the href specified for that relation. 

The previous tag and pact endpoints are still supported, however, future features that build on this endpoint may not be able to be backported into those endpoints.

This endpoint is designed to be used by a command line tool, and hence, the response notices are designed for output to the user in a terminal.

## Parameters

* `pacticipantName`: the name of the application. Required.
* `pacticipantVersionNumber`: the version number of the application. Required. It is recommended that this should be or include the git SHA. See [http://docs.pact.io/versioning](http://docs.pact.io/versioning).
* `branch`: The git branch name. Optional but strongly recommended.
* `tags`: The consumer version tags. Use of the branch parameter is preferred now. Optional.
* `buildUrl`: The CI/CD build URL. Optional.
* `contracts`
  * `consumerName`: the name of the consumer. Required. Must match the pacticipant name and the consumer name inside the pact. While this field may seem redundant currently, this endpoint will be extended to support publication of provider generated, non-pact contracts, and the consumerName and providerName fields will be used to indicate which role the pacticipant is taking in the contract.
  * `providerName`: the name of the provider. Required.
  * `specification`: currently, only contracts of type "pact" are supported, but this will be extended in the future. Required.
  * `contentType`: currently, only contracts with a content type of "application/json" are supported. Required.
  * `content`: the content of the contract. Must be Base64 encoded. Required.

## Responses

### Success

* `notices`
  * `type`: one of `debug`, `info`, `warning`,`prompt`,`success`, `error`, `danger`
  * `text`: the text of the notice. This is designed to be displayed in the output of a CLI.

The `_links` section will contain links to all the resources created by the publication. The relations are:

* `pb:contracts` (array)
* `pb:pacticipant-version-tags` (array)
* `pb:pacticipant-version`
* `pb:pacticipant`

### Errors

### Schema validation errors

Any validation errors will be returned in the standard Pact Broker format with a 400 status:

    {
      "errors": {
        "<fieldName>": ["message 1", "message 2"]
      }
    }

### Contract conflict errors

If there is a conflict with an existing published pact and `allow_dangerous_contract_modification` is set to false, a 409 will be returned with an array of notices, which will contain a diff between the existing pact content and the content that was attempted to be published. For consistency with the existing error responses, the errors hash will also contain the error messages, but there will be no diff included. For CLI usage, when there are notices and errors, just the notices should be displayed to the user.

    {
        "notices":
        [
            {
                "text": "Cannot change the content of the pact for Foo version 183a77b0 and provider Bar, as race conditions will cause unreliable results for can-i-deploy. Each pact must be published with a unique consumer version number. For more information see https://docs.pact.io/go/versioning",
                "type": "error"
            },
            {
                "text": "<the diff, will include new lines>",
                "type": "info"
            }
        ],
        "errors":
        {
            "content":
            [
                "Cannot change the content of the pact for Foo version 183a77b0 and provider Bar, as race conditions will cause unreliable results for can-i-deploy. Each pact must be published with a unique consumer version number. For more information see https://docs.pact.io/go/versioning"
            ]
        }
    }


## Example

    POST http://broker/contracts/publish
    {
      "pacticipantName": "Foo",
      "pacticipantVersionNumber": "dc5eb529230038a4673b8c971395bd2922d8b240",
      "branch": "main",
      "tags": ["main"],
      "buildUrl": "https://ci/builds/1234",
      "contracts": [
        {
          "consumerName": "Foo",
          "providerName": "Bar",
          "specification": "pact",
          "contentType": "application/json",
          "content": "<base64 encoded JSON pact>"
        }
      ]
    }
    
    {
      {
        "notices": [
          {
            "type": "debug",
            "text": "Created Foo version dc5eb529230038a4673b8c971395bd2922d8b240 with branch main and tags main"
          },
          {
            "type": "info",
            "text": "Pact published for Foo version dc5eb529230038a4673b8c971395bd2922d8b240 and provider Bar."
          },
          {
            "type": "debug",
            "text": "  Events detected: contract_published, contract_content_changed (first time any pact published for this consumer with consumer version tagged main)"
          },
          {
            "type": "debug",
            "text": "  Webhook \"foo webhook\" triggered for event contract_content_changed.\n    See logs at http://example.org/triggered-webhooks/1234/logs\""
          }
        ],
        "_embedded": {
          "pacticipant": {
            "name": "Foo",
            "_links": {
              "self": {
                "href": "http://example.org/pacticipants/Foo"
              }
            }
          },
          "version": {
            "number": "1",
            "branch": "main",
            "buildUrl": "http://ci/builds/1234",
            "_links": {
              "self": {
                "title": "Version",
                "name": "dc5eb529230038a4673b8c971395bd2922d8b240",
                "href": "http://example.org/pacticipants/Foo/versions/dc5eb529230038a4673b8c971395bd2922d8b240"
              }
            }
          }
        },
        "_links": {
          "pb:pacticipant": {
            "title": "Pacticipant",
            "name": "Foo",
            "href": "http://example.org/pacticipants/Foo"
          },
          "pb:pacticipant-version": {
            "title": "Pacticipant version",
            "name": "1",
            "href": "http://example.org/pacticipants/Foo/versions/dc5eb529230038a4673b8c971395bd2922d8b240"
          },
          "pb:pacticipant-version-tags": [
            {
              "title": "Tag",
              "name": "a",
              "href": "http://example.org/pacticipants/Foo/versions/dc5eb529230038a4673b8c971395bd2922d8b240/tags/a"
            },
            {
              "title": "Tag",
              "name": "b",
              "href": "http://example.org/pacticipants/Foo/versions/dc5eb529230038a4673b8c971395bd2922d8b240/tags/b"
            }
          ],
          "pb:contracts": [
            {
              "title": "Pact",
              "name": "Pact between Foo (dc5eb529230038a4673b8c971395bd2922d8b240) and Bar",
              "href": "http://example.org/pacts/provider/Bar/consumer/Foo/version/dc5eb529230038a4673b8c971395bd2922d8b240"
            }
          ]
        }
      }
    }

