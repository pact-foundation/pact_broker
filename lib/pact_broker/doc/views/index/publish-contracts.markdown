# Publish Contracts

Allowed methods: `POST`

Path: `/contracts/publish`

## Example

    POST http://broker/contracts/publish
    {
      "pacticipantName": "Foo",
      "versionNumber": "dc5eb529230038a4673b8c971395bd2922d8b240",
      "tags": ["main"],
      "branch": "main",
      "buildUrl": "https://ci/builds/1234",
      "contracts": [
        {
          "role": "consumer",
          "providerName": "Bar",
          "contractSpecification": "pact",
          "contentType": "application/json",
          "content": "<base64 encoded JSON pact>"
        }
      ]
    }
