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

* **Scheme**: Must be included in the `webhook_scheme_whitelist`, which by default only includes `https`. You can change this to include `http` if absolutely necessary, however, keep in mind that the body of any http traffic is visible to the network. You can load a self signed certificate into the Pact Broker to be used for https connections using [script/insert-self-signed-certificate-from-url.rb](https://github.com/pact-foundation/pact_broker/blob/master/script/insert-self-signed-certificate-from-url.rb) in the
Pact Broker Github repository.

* **HTTP method**: Must be included in the `webhook_http_method_whitelist`, which by default only includes `POST`. It is highly recommended that only `POST` requests are allowed to ensure that webhooks cannot be used to retrieve sensitive information from hosts within the same network.

* **Host**: If the `webhook_host_whitelist` contains any entries, the host must match one or more of the entries. By default, it is empty. For security purposes, if the host whitelist is empty, the response details will not be logged to the UI (though they can be seen in the application logs at debug level).

  The host whitelist may contain hostnames (eg `"github.com"`), IPs (eg `"192.0.345.4"`), network ranges (eg `"10.0.0.0/8"`) or regular expressions (eg `/.*\.foo\.com$/`). Note that IPs are not resolved, so if you specify an IP range, you need to use the IP in the webhook URL. If you wish to allow webhooks to any host (not recommended!), you can set `webhook_host_whitelist` to `[/.*/]`. Beware of any sensitive endpoints that may be exposed within the same network.

  The recommended set of values to start with are:

    * your CI server's hostname (for triggering builds)
    * your company chat (eg. Slack, for publishing notifications)
    * your code repository (eg. Github, for sending commit statuses)

  Alternatively, you could use a regular expression to limit requests to your company's domain. eg `/.*\.foo\.com$/` (don't forget the end of string anchor). You can test Ruby regular expressions at [rubular.com](http://rubular.com).

#### Event types

`contract_content_changed:` triggered when the content of the contract has changed since the previous publication. Uses plain string equality, so changes to the ordering of hash keys, or whitespace changes will trigger this webhook.

`provider_verification_published:` triggered whenever a provider publishes a verification.

### Dynamic variable substitution

The following variables may be used in the request parameters or body, and will be replaced with their appropriate values at runtime.

`${pactbroker.consumerName}`: the consumer name
`${pactbroker.providerName}`: the provider name
`${pactbroker.consumerVersionNumber}`: the version number of the most recent consumer version associated with the pact content.
`${pactbroker.providerVersionNumber}`: the provider version number for the verification result
`${pactbroker.consumerVersionTags}`: the list of tag names for the most recent consumer version associated with the pact content, separated by ", ".
`${pactbroker.providerVersionTags}`: the list of tag names for the provider version associated with the verification result, separated by ", ".
`${pactbroker.githubVerificationStatus}`: the verification status using the correct keywords for posting to the the [Github commit status API](https://developer.github.com/v3/repos/statuses).
`${pactbroker.pactUrl}`: the "permalink" URL to the newly published pact (the URL specifying the consumer version URL, rather than the "/latest" format.)
`${pactbroker.verificationResultUrl}`: the URL to the relevant verification result.

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
