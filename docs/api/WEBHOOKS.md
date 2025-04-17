
# Webhooks


## Webhook

Path: `/webhooks/:uuid`<br/>
Allowed methods: `GET`, `PUT`, `DELETE`<br/>

### GET

#### Request

Headers: `{"Accept":"application/hal+json"}`<br/>


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "uuid": "d2181b32-8b03-4daf-8cc0-d9168b2f6fac",
  "description": "an example webhook",
  "consumer": {
    "name": "Foo"
  },
  "provider": {
    "name": "Bar"
  },
  "enabled": true,
  "request": {
    "method": "POST",
    "url": "https://example.org/webhook",
    "headers": {
      "Content-Type": "application/json"
    },
    "body": {
      "pactUrl": "${pactbroker.pactUrl}"
    }
  },
  "events": [
    {
      "name": "contract_content_changed"
    }
  ],
  "createdAt": "2021-09-01T00:07:21+00:00",
  "_links": {
    "self": {
      "title": "an example webhook",
      "href": "https://pact-broker/webhooks/d2181b32-8b03-4daf-8cc0-d9168b2f6fac"
    },
    "pb:execute": {
      "title": "Test the execution of the webhook with the latest matching pact or verification by sending a POST request to this URL",
      "href": "https://pact-broker/webhooks/d2181b32-8b03-4daf-8cc0-d9168b2f6fac/execute"
    },
    "pb:consumer": {
      "title": "Consumer",
      "name": "Foo",
      "href": "https://pact-broker/pacticipants/Foo"
    },
    "pb:provider": {
      "title": "Provider",
      "name": "Bar",
      "href": "https://pact-broker/pacticipants/Bar"
    },
    "pb:pact-webhooks": {
      "title": "All webhooks for consumer Foo and provider Bar",
      "href": "https://pact-broker/webhooks/provider/Bar/consumer/Foo"
    },
    "pb:webhooks": {
      "title": "All webhooks",
      "href": "https://pact-broker/webhooks"
    }
  }
}
```


### PUT

#### Request

Headers: `{"Content-Type":"application/json","Accept":"application/hal+json"}`<br/>
Body:

```
{
  "description": "an example webhook",
  "events": [
    {
      "name": "contract_content_changed"
    }
  ],
  "request": {
    "method": "POST",
    "url": "https://example.org/example",
    "username": "username",
    "password": "password",
    "headers": {
      "Accept": "application/json"
    },
    "body": {
      "pactUrl": "${pactbroker.pactUrl}"
    }
  }
}
```


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "uuid": "d2181b32-8b03-4daf-8cc0-d9168b2f6fac",
  "description": "an example webhook",
  "enabled": true,
  "request": {
    "method": "POST",
    "url": "https://example.org/example",
    "headers": {
      "Accept": "application/json"
    },
    "body": {
      "pactUrl": "${pactbroker.pactUrl}"
    },
    "username": "username",
    "password": "**********"
  },
  "events": [
    {
      "name": "contract_content_changed"
    }
  ],
  "createdAt": "2021-09-01T00:07:21+00:00",
  "_links": {
    "self": {
      "title": "an example webhook",
      "href": "https://pact-broker/webhooks/d2181b32-8b03-4daf-8cc0-d9168b2f6fac"
    },
    "pb:execute": {
      "title": "Test the execution of the webhook with the latest matching pact or verification by sending a POST request to this URL",
      "href": "https://pact-broker/webhooks/d2181b32-8b03-4daf-8cc0-d9168b2f6fac/execute"
    },
    "pb:webhooks": {
      "title": "All webhooks",
      "href": "https://pact-broker/webhooks"
    }
  }
}
```



## Webhooks

Path: `/webhooks`<br/>
Allowed methods: `GET`, `POST`<br/>

### GET

#### Request

Headers: `{"Accept":"application/hal+json"}`<br/>


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "_links": {
    "self": {
      "title": "Webhooks",
      "href": "http://example.org/webhooks"
    },
    "pb:create": {
      "title": "POST to create a webhook",
      "href": "http://example.org/webhooks"
    },
    "pb:webhooks": [
      {
        "title": "A webhook for the pact between Foo and Bar",
        "name": "an example webhook",
        "href": "https://pact-broker/webhooks/d2181b32-8b03-4daf-8cc0-d9168b2f6fac"
      }
    ],
    "curies": [
      {
        "name": "pb",
        "href": "https://pact-broker/doc/webhooks-{rel}",
        "templated": true
      }
    ]
  }
}
```


### POST

#### Request

Headers: `{"Content-Type":"application/json","Accept":"application/hal+json"}`<br/>
Body:

```
{
  "description": "an example webhook",
  "events": [
    {
      "name": "contract_content_changed"
    }
  ],
  "request": {
    "method": "POST",
    "url": "https://example.org/example",
    "username": "username",
    "password": "password",
    "headers": {
      "Accept": "application/json"
    },
    "body": {
      "pactUrl": "${pactbroker.pactUrl}"
    }
  }
}
```


#### Response

Status: `201`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8","Location":"https://pact-broker/webhooks/67c2884a-5773-5c8b-93e7-0776f1cda018"}`<br/>
Body:

```
{
  "uuid": "67c2884a-5773-5c8b-93e7-0776f1cda018",
  "description": "an example webhook",
  "enabled": true,
  "request": {
    "method": "POST",
    "url": "https://example.org/example",
    "headers": {
      "Accept": "application/json"
    },
    "body": {
      "pactUrl": "${pactbroker.pactUrl}"
    },
    "username": "username",
    "password": "**********"
  },
  "events": [
    {
      "name": "contract_content_changed"
    }
  ],
  "createdAt": "2021-09-01T00:07:21+00:00",
  "_links": {
    "self": {
      "title": "an example webhook",
      "href": "https://pact-broker/webhooks/67c2884a-5773-5c8b-93e7-0776f1cda018"
    },
    "pb:execute": {
      "title": "Test the execution of the webhook with the latest matching pact or verification by sending a POST request to this URL",
      "href": "https://pact-broker/webhooks/67c2884a-5773-5c8b-93e7-0776f1cda018/execute"
    },
    "pb:webhooks": {
      "title": "All webhooks",
      "href": "https://pact-broker/webhooks"
    }
  }
}
```



## Webhooks for consumer

Path: `/webhooks/consumer/:consumer_name`<br/>
Allowed methods: `POST`, `GET`<br/>

### GET

#### Request

Headers: `{"Accept":"application/hal+json"}`<br/>


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "_links": {
    "self": {
      "title": "Webhooks",
      "href": "http://example.org/webhooks/consumer/Foo"
    },
    "pb:create": {
      "title": "POST to create a webhook",
      "href": "http://example.org/webhooks/consumer/Foo"
    },
    "pb:webhooks": [

    ],
    "curies": [
      {
        "name": "pb",
        "href": "https://pact-broker/doc/webhooks-{rel}",
        "templated": true
      }
    ]
  }
}
```



## Webhooks for a provider

Path: `/webhooks/provider/:provider_name`<br/>
Allowed methods: `POST`, `GET`<br/>

### GET

#### Request

Headers: `{"Accept":"application/hal+json"}`<br/>


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "_links": {
    "self": {
      "title": "Webhooks",
      "href": "http://example.org/webhooks/provider/Bar"
    },
    "pb:create": {
      "title": "POST to create a webhook",
      "href": "http://example.org/webhooks/provider/Bar"
    },
    "pb:webhooks": [

    ],
    "curies": [
      {
        "name": "pb",
        "href": "https://pact-broker/doc/webhooks-{rel}",
        "templated": true
      }
    ]
  }
}
```



## Webhooks for consumer and provider

Path: `/webhooks/provider/:provider_name/consumer/:consumer_name`<br/>
Allowed methods: `POST`, `GET`<br/>

### GET

#### Request

Headers: `{"Accept":"application/hal+json"}`<br/>


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "_links": {
    "self": {
      "title": "Webhooks",
      "href": "http://example.org/webhooks/provider/Bar/consumer/Foo"
    },
    "pb:create": {
      "title": "POST to create a webhook",
      "href": "http://example.org/webhooks/provider/Bar/consumer/Foo"
    },
    "pb:webhooks": [
      {
        "title": "A webhook for the pact between Foo and Bar",
        "name": "an example webhook",
        "href": "https://pact-broker/webhooks/d2181b32-8b03-4daf-8cc0-d9168b2f6fac"
      }
    ],
    "curies": [
      {
        "name": "pb",
        "href": "https://pact-broker/doc/webhooks-{rel}",
        "templated": true
      }
    ]
  }
}
```



## Pact webhooks

Path: `/pacts/provider/:provider_name/consumer/:consumer_name/webhooks`<br/>
Allowed methods: `POST`, `GET`<br/>

### GET

#### Request

Headers: `{"Accept":"application/hal+json"}`<br/>


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "_links": {
    "self": {
      "title": "Pact webhooks",
      "href": "http://example.org/pacts/provider/Bar/consumer/Foo/webhooks"
    },
    "pb:create": {
      "title": "POST to create a webhook",
      "href": "http://example.org/pacts/provider/Bar/consumer/Foo/webhooks"
    },
    "pb:webhooks": [
      {
        "title": "A webhook for the pact between Foo and Bar",
        "name": "an example webhook",
        "href": "https://pact-broker/webhooks/d2181b32-8b03-4daf-8cc0-d9168b2f6fac"
      }
    ],
    "curies": [
      {
        "name": "pb",
        "href": "https://pact-broker/doc/webhooks-{rel}",
        "templated": true
      }
    ]
  }
}
```



## Webhooks status

Path: `/pacts/provider/:provider_name/consumer/:consumer_name/webhooks/status`<br/>
Allowed methods: `GET`<br/>

### GET

#### Request

Headers: `{"Accept":"application/hal+json"}`<br/>


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "summary": {
    "successful": 0,
    "failed": 0,
    "notRun": 1
  },
  "_embedded": {
    "triggeredWebhooks": [
      {
        "name": "POST example.org",
        "status": "not_run",
        "attemptsMade": 1,
        "attemptsRemaining": 6,
        "triggerType": "resource_creation",
        "eventName": "contract_content_changed",
        "triggeredAt": "2021-09-01T00:07:21+00:00",
        "_links": {
          "pb:logs": {
            "href": "https://pact-broker/triggered-webhooks/6cd5cc48-db3c-4a4c-a36d-e9bedeb9d91e/logs",
            "title": "Webhook execution logs",
            "name": "POST example.org"
          },
          "pb:webhook": {
            "href": "https://pact-broker/webhooks/d2181b32-8b03-4daf-8cc0-d9168b2f6fac",
            "title": "Webhook",
            "name": "POST example.org"
          }
        }
      }
    ]
  },
  "_links": {
    "self": {
      "href": "http://example.org/pacts/provider/Bar/consumer/Foo/webhooks/status",
      "title": "Webhooks status"
    },
    "pb:error-logs": [

    ],
    "pb:pact-webhooks": {
      "title": "Webhooks for the pact between Foo and Bar",
      "href": "https://pact-broker/pacts/provider/Bar/consumer/Foo/webhooks"
    },
    "pb:pact-version": {
      "href": "https://pact-broker/pacts/provider/Bar/consumer/Foo/version/3e1f00a04",
      "title": "Pact",
      "name": "Pact between Foo (3e1f00a04) and Bar"
    },
    "pb:consumer": {
      "href": "https://pact-broker/pacticipants/Foo",
      "title": "Consumer",
      "name": "Foo"
    },
    "pb:provider": {
      "href": "https://pact-broker/pacticipants/Bar",
      "title": "Provider",
      "name": "Bar"
    }
  }
}
```



## Executing a saved webhook

Path: `/webhooks/:uuid/execute`<br/>
Allowed methods: `POST`<br/>

### POST

#### Request

Headers: `{"Content-Type":"application/json","Accept":"application/hal+json"}`<br/>


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "request": {
    "headers": {
      "accept": "*/*",
      "user-agent": "Pact Broker",
      "content-type": "application/json"
    },
    "body": {
      "pactUrl": "https://pact-broker/pacts/provider/Bar/consumer/Foo/pact-version/3e193ecb37ad04b43ce974a38352c704b2e0ed6b/metadata/3e193ecb37ad04b43ce974a38352c704b2e0ed6b"
    },
    "url": "/webhook"
  },
  "response": {
    "status": 200,
    "headers": {
    },
    "body": ""
  },
  "logs": "[2021-09-01T10:07:21Z] DEBUG: Webhook context {\"base_url\":\"https://pact-broker\",\"event_name\":\"test\"}\n[2021-09-01T10:07:21Z] INFO: HTTP/1.1 POST https://example.org/webhook\n[2021-09-01T10:07:21Z] INFO: accept: */*\n[2021-09-01T10:07:21Z] INFO: user-agent: Pact Broker\n[2021-09-01T10:07:21Z] INFO: content-type: application/json\n[2021-09-01T10:07:21Z] INFO: {\"pactUrl\":\"https://pact-broker/pacts/provider/Bar/consumer/Foo/pact-version/3e193ecb37ad04b43ce974a38352c704b2e0ed6b/metadata/3e193ecb37ad04b43ce974a38352c704b2e0ed6b\"}\n[2021-09-01T10:07:21Z] INFO: HTTP/1.0 200 \n[2021-09-01T10:07:21Z] INFO: \n",
  "success": true,
  "_links": {
  }
}
```



## Executing an unsaved webhook

Path: `/webhooks/execute`<br/>
Allowed methods: `POST`<br/>

### POST

#### Request

Headers: `{"Content-Type":"application/json","Accept":"application/hal+json"}`<br/>
Body:

```
{
  "description": "an example webhook",
  "events": [
    {
      "name": "contract_content_changed"
    }
  ],
  "request": {
    "method": "POST",
    "url": "https://example.org/example",
    "username": "username",
    "password": "password",
    "headers": {
      "Accept": "application/json"
    },
    "body": {
      "pactUrl": "${pactbroker.pactUrl}"
    }
  }
}
```


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "request": {
    "headers": {
      "accept": "application/json",
      "user-agent": "Pact Broker",
      "authorization": "**********"
    },
    "body": {
      "pactUrl": "https://pact-broker/pacts/provider/Bar/consumer/Foo/pact-version/3e193ecb37ad04b43ce974a38352c704b2e0ed6b/metadata/3e193ecb37ad04b43ce974a38352c704b2e0ed6b"
    },
    "url": "/example"
  },
  "response": {
    "status": 200,
    "headers": {
    },
    "body": ""
  },
  "logs": "[2021-09-01T10:07:21Z] DEBUG: Webhook context {\"base_url\":\"https://pact-broker\",\"event_name\":\"test\"}\n[2021-09-01T10:07:21Z] INFO: HTTP/1.1 POST https://example.org/example\n[2021-09-01T10:07:21Z] INFO: accept: application/json\n[2021-09-01T10:07:21Z] INFO: user-agent: Pact Broker\n[2021-09-01T10:07:21Z] INFO: authorization: **********\n[2021-09-01T10:07:21Z] INFO: {\"pactUrl\":\"https://pact-broker/pacts/provider/Bar/consumer/Foo/pact-version/3e193ecb37ad04b43ce974a38352c704b2e0ed6b/metadata/3e193ecb37ad04b43ce974a38352c704b2e0ed6b\"}\n[2021-09-01T10:07:21Z] INFO: HTTP/1.0 200 \n[2021-09-01T10:07:21Z] INFO: \n",
  "success": true,
  "_links": {
  }
}
```



## Triggered webhooks for pact publication

Path: `/pacts/provider/:provider_name/consumer/:consumer_name/version/:consumer_version_number/triggered-webhooks`<br/>
Allowed methods: `GET`<br/>

### GET

#### Request

Headers: `{"Accept":"application/hal+json"}`<br/>


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "_embedded": {
    "triggeredWebhooks": [
      {
        "name": "POST example.org",
        "status": "not_run",
        "attemptsMade": 1,
        "attemptsRemaining": 6,
        "triggerType": "resource_creation",
        "eventName": "contract_content_changed",
        "triggeredAt": "2021-09-01T00:07:21+00:00",
        "_links": {
          "pb:logs": {
            "href": "https://pact-broker/triggered-webhooks/6cd5cc48-db3c-4a4c-a36d-e9bedeb9d91e/logs",
            "title": "Webhook execution logs",
            "name": "POST example.org"
          },
          "pb:webhook": {
            "href": "https://pact-broker/webhooks/d2181b32-8b03-4daf-8cc0-d9168b2f6fac",
            "title": "Webhook",
            "name": "POST example.org"
          }
        }
      }
    ]
  },
  "_links": {
    "self": {
      "title": "Webhooks triggered by the publication of the pact between Foo (3e1f00a04) and Bar",
      "href": "http://example.org/pacts/provider/Bar/consumer/Foo/version/3e1f00a04/triggered-webhooks"
    }
  }
}
```



## Triggered webhooks for verification publication

Path: `/pacts/provider/:provider_name/consumer/:consumer_name/pact-version/:pact_version_sha/verification-results/:verification_number/triggered-webhooks`<br/>
Allowed methods: `GET`<br/>

### GET

#### Request

Headers: `{"Accept":"application/hal+json"}`<br/>


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"application/hal+json;charset=utf-8"}`<br/>
Body:

```
{
  "_embedded": {
    "triggeredWebhooks": [

    ]
  },
  "_links": {
    "self": {
      "title": "Webhooks triggered by the publication of verification result 1",
      "href": "http://example.org/pacts/provider/Bar/consumer/Foo/pact-version/3e193ecb37ad04b43ce974a38352c704b2e0ed6b/verification-results/1/triggered-webhooks"
    }
  }
}
```



## Logs of triggered webhook

Path: `/triggered-webhooks/:uuid/logs`<br/>
Allowed methods: `GET`<br/>

### GET

#### Request

Headers: `{"Accept":"application/hal+json"}`<br/>


#### Response

Status: `200`<br/>
Headers: `{"Content-Type":"text/plain;charset=utf-8"}`<br/>
Body:

```
logs
```
