# A pact between Some Consumer and Some Provider

### Requests from Some Consumer to Some Provider

* [A request for alligators in Brüssel](#a_request_for_alligators_in_Brüssel_given_alligators_exist) given alligators exist

* [A request for polar bears](#a_request_for_polar_bears)

### Interactions

<a name="a_request_for_alligators_in_Brüssel_given_alligators_exist"></a>
Given **alligators exist**, upon receiving **a request for alligators in Brüssel** from Some Consumer, with
```json
{
  "method": "get",
  "path": "/alligators"
}
```
Some Provider will respond with:
```json
{
  "status": 200,
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "alligators": [
      {
        "name": "Bob",
        "phoneNumber": {
          "json_class": "Pact::Term",
          "data": {
            "generate": "12345678",
            "matcher": {
              "json_class": "Regexp",
              "o": 0,
              "s": "\\d+"
            }
          }
        }
      }
    ]
  }
}
```
<a name="a_request_for_polar_bears"></a>
Upon receiving **a request for polar bears** from Some Consumer, with
```json
{
  "method": "get",
  "path": "/polar-bears"
}
```
Some Provider will respond with:
```json
{
  "status": 404,
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "message": "Sorry, due to climate change, the polar bears are currently unavailable."
  }
}
```
