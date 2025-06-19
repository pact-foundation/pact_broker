# A pact between Consumer and Provider

### Requests from Consumer to Provider

* [A message interaction](#a_message_interaction_given_provider_is_at_state_one) given provider is at state one and provider is at state two

* [A request for alligators](#a_request_for_alligators_given_alligators_exist)

* [Another message interaction](#another_message_interaction)

### Interactions

<a name="a_message_interaction_given_provider_is_at_state_one"></a>
Given **provider is at state one** and **provider is at state two**

Provider will **asyncronously** send **a message interaction**:
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
<a name="another_message_interaction"></a>


Provider will **asyncronously** send **another message interaction**:
```json
{
  "contents": {
    "something": "other content"
  },
  "metadata": {
    "where": "location"
  }
}
```
