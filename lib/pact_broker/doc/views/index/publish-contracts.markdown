# Publish Contracts

Allowed methods: `POST`

Path: `/contracts/publish`

This is the preferred endpoint with which to publish contracts (previously, contracts were published using multiple calls to different endpoints to create each of the tag and contract resources). To detect whether this endpoint exists in a particular version of the Pact Broker, make a request to the index resource, and locate the "pb:publish-contracts" relation. Do a `POST` to the href specified for that relation. 

The previous tag and pact endpoints are still supported, however, future features that build on this endpoint may not be able to be backported into those endpoints (eg. publishing pacts with a branch).

## Example

    POST http://broker/contracts/publish
    {
      "pacticipantName": "Foo",
      "pacticipantVersionNumber": "dc5eb529230038a4673b8c971395bd2922d8b240",
      "tags": ["main"],
      "branch": "main",
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
        "logs": [
          {
            "level": "debug",
            "message": "Created Foo version dc5eb529230038a4673b8c971395bd2922d8b240 with branch main and tags main"
          },
          {
            "level": "info",
            "message": "Pact published for Foo version dc5eb529230038a4673b8c971395bd2922d8b240 and provider Bar."
          },
          {
            "level": "debug",
            "message": "  Events detected: contract_published, contract_content_changed (first time any pact published for this consumer with consumer version tagged main)"
          },
          {
            "level": "debug",
            "message": "  Webhook \"foo webhook\" triggered for event contract_content_changed.\n    See logs at http://example.org/triggered-webhooks/1234/logs\""
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
                "name": "1",
                "href": "http://example.org/pacticipants/Foo/versions/1"
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
