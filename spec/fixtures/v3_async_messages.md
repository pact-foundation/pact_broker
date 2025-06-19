# A pact between Consumer and Provider

### Requests from Consumer to Provider

* [A message interaction](#a_message_interaction_given_provider_is_at_state_one) given provider is at state one and provider is at state two

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
