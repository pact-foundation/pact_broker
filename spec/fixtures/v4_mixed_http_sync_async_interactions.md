# A pact between Consumer and Provider

### Requests from Consumer to Provider

* [A request for alligators](#a_request_for_alligators_given_alligators_exist)

* [Async message interaction](#async_message_interaction_given_provider_is_at_state_one) given provider is at state one and provider is at state two

* [Sync message interaction](#sync_message_interaction)

### Interactions

<a name="a_request_for_alligators_given_alligators_exist"></a>
Upon receiving **a request for alligators** from Consumer, with
```json
{
  "method": "get",
  "path": "/alligators"
}
```
Provider will respond with:
```json
{
  "status": 200,
  "body": {
    "alligators": [
      {
        "name": "Bob",
        "phoneNumber": "12345678"
      }
    ]
  }
}
```
<a name="async_message_interaction_given_provider_is_at_state_one"></a>
Given **provider is at state one** and **provider is at state two**

Provider will **asyncronously** send **async message interaction**:
```json
{
  "contents": {
    "some": "content"
  },
  "metadata": {
    "meta": "data"
  }
}
```
<a name="sync_message_interaction"></a>
Upon receiving **sync message interaction** from Consumer, with
```json
{
  "contents": {
    "content": "ChJwbHVnaW4tZHJpdmVyLXJ1c3QSBTAuMC4w",
    "contentType": "application/protobuf;message=InitPluginRequest",
    "contentTypeHint": "BINARY",
    "encoded": "base64"
  },
  "metadata": {
    "requestKey1": "value",
    "requestKey2": "value2"
  }
}
```
Provider will respond with:
```json
[
  {
    "contents": {
      "content": "CggIABIEdGVzdA==",
      "contentType": "application/protobuf;message=InitPluginResponse",
      "contentTypeHint": "BINARY",
      "encoded": "base64"
    },
    "metadata": {
      "responseKey1": "value",
      "responseKey2": "value2"
    }
  }
]
```