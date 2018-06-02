# Webhooks

*Collection resource*

Path: `/webhooks/provider/PROVIDER/consumer/CONSUMER`

Allowed methods: `GET`, `POST`

*Individual resource*

Path: `/webhook
s/UUID`

Allowed methods: `GET`, `PUT`, `DELETE`

### Creating

1. To create a webhook, in the HAL Browser, navigate to the pact you want to create the webhook for
(Click "Go to Entry Point", then select "latest-pacts", then select the pact you want to create the webhook for.)
2. Click the "NON-GET" button for the "pact-webhooks" relation.
3. Paste in the webhook JSON (example shown below) in the body section and click "Make Request".

An example webhook to trigger a Bamboo job when a contract has changed.

    {
      "events": [{
        "name": "contract_content_changed"
      }],
      "request": {
        "method": "POST",
        "url": "http://master.ci.my.domain:8085/rest/api/latest/queue/SOME-PROJECT?os_authType=basic",
        "username": "username",
        "password": "password",
        "headers": {
          "Accept": "application/json"
        }
      }
    }

A request body can be specified as well.

    {
      "events": [{
        "name": "contract_content_changed"
      }],
      "request": {
        "method": "POST",
        "url": "http://example.org/something",
        "body": {
          "some" : "json"
        }
      }
    }

**BEWARE** The password can be reverse engineered from the database, so make a separate account for the Pact Broker to use, don't use your personal account!

<a name="whitelist"></a>
#### Webhook Whitelist

To ensure that webhooks cannot be used maliciously to expose either data about your contracts or your internal network, the following validation rules are applied to webhooks via the Pact Broker configuration settings.

* **Scheme**: Must be included in the `webhook_scheme_whitelist`, which by default only includes `https`. You can change this to include `http` if absolutely necessary, however, keep in mind that the body of any http traffic is visible to the network. You can load a self signed certificate into the Pact Broker to be used for https connections using `script/insert-self-signed-certificate-from-url.rb` in the Pact Broker repository.

* **HTTP method**: Must be included in the `webhook_http_method_whitelist`, which by default only includes `POST`. It is highly recommended that only `POST` requests are allowed to ensure that webhooks cannot be used to retrieve sensitive information from hosts within the same network.

#### Event types

`contract_content_changed:` triggered when the content of the contract has changed since the previous publication. Uses plain string equality, so changes to the ordering of hash keys, or whitespace changes will trigger this webhook.

`provider_verification_published:` triggered whenever a provider publishes a verification.

### Dynamic variable substitution

The following variables may be used in the request parameters or body, and will be replaced with their appropriate values at runtime.

`${pactbroker.pactUrl}`: the "permalink" URL to the newly published pact (the URL specifying the consumer version URL, rather than the "/latest" format.)
`${pactbroker.consumerVersionNumber}`: the version number of the most recent consumer version associated with the pact content.

Example usage:

    {
      "events": [{
        "name": "contract_content_changed"
      }],
      "request": {
        "method": "POST",
        "url": "http://example.org/something",
        "body": {
          "thisPactWasPublished" : "${pactbroker.pactUrl}"
        }
      }
    }

### Testing

To test a webhook, navigate to the webhook in the HAL browser, then make a POST request to the "execute" relation. The response or error will be shown in the window.

### Deleting

Send a DELETE request to the webhook URL.

### Updating

Send a PUT request to the webhook URL with all fields required for the new webhook.
