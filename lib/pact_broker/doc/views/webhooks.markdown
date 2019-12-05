# Webhooks

*Collection resource*

Path: `/webhooks`

Allowed methods: `GET`, `POST`

*Individual resource*

Path: `/webhook/UUID`

Allowed methods: `GET`, `PUT`, `DELETE`

Webhooks are HTTP requests that are executed asynchronously after certain events occur in the Pact Broker, that can be used to create a workflow or notify people of changes to the data contained in the Pact Broker. The most common use for webhooks is to trigger builds when a pact has changed or a verification result has been published, but they can also be used for conveying information like posting notifications to Slack, or commit statuses to Github.

### Creating

To create a webhook, send a `POST` request to `/webhooks` with the body described below. You can do this through the API Browser by clicking on the `NON-GET` button for the `pb:webhooks` relation on the index, pasting in the JSON body, and clicking "Make Request".

Below is an example webhook to trigger a Bamboo job when any contract for the provider "Foo" has changed. Both provider and consumer are optional - omitting either indicates that any pacticipant in that role will be matched. Webhooks with neither provider nor consumer specified are "global" webhooks that will trigger for any consumer/provider pair.

    {
      "provider": {
        "name": "Bar"
      },
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
        "headers": {
          "Content-Type": "application/json"
        },
        "body": {
          "some" : "json"
        }
      }
    }

To specify an XML body, you will need to use a correctly escaped string (or use single quotes if allowed).

        {
          "events": [{
            "name": "contract_content_changed"
          }],
          "request": {
            "method": "POST",
            "url": "http://example.org/something",
            "headers": {
              "Content-Type": "application/xml"
            },
            "body": "<xml \"foo\"=\"bar\"></xml>"
          }
        }

**BEWARE** While the basic auth password, and any header containing the word `authorization` or `token` will be redacted from the UI and the logs, the password could be reverse engineered from the database, so make a separate account for the Pact Broker to use in your webhooks. Don't use your personal account!

#### Event types

`contract_published:` triggered every time a contract is published. It is not recommended to trigger your provider verification build every time a contract is published - see `contract_content_changed` below.

`contract_content_changed:` triggered when the content of the contract, or tags applied to the contract have changed since the previous publication. If `base_equality_only_on_content_that_affects_verification_results` is set to `true` in the configuration (the default), any changes to whitespace, ordering of keys, or the ordering of the `interactions` or `messages` will be ignored, and will not trigger this event. It is recommended to trigger a provider verification build for this event.

`provider_verification_published:` triggered whenever a provider publishes a verification result.

`provider_verification_succeeded:` triggered whenever a provider publishes a successful verification result.

`provider_verification_failed:` triggered whenever a provider publishes a failed verification result.

### Dynamic variable substitution

The following variables may be used in the request path, parameters or body, and will be replaced with their appropriate values at runtime.

* `${pactbroker.consumerName}`: the consumer name
* `${pactbroker.providerName}`: the provider name
* `${pactbroker.consumerVersionNumber}`: the version number of the most recent consumer version associated with the pact content.
* `${pactbroker.providerVersionNumber}`: the provider version number for the verification result
* `${pactbroker.consumerVersionTags}`: the list of tag names for the most recent consumer version associated with the pact content, separated by ", ".
* `${pactbroker.providerVersionTags}`: the list of tag names for the provider version associated with the verification result, separated by ", ".
* `${pactbroker.consumerLabels}`: the list of labels for the consumer associated with the pact content, separated by ", ".
* `${pactbroker.providerLabels}`: the list of labels for the provider associated with the pact content, separated by ", ".
* `${pactbroker.githubVerificationStatus}`: the verification status using the correct keywords for posting to the the [Github commit status API](https://developer.github.com/v3/repos/statuses).
* `${pactbroker.bitbucketVerificationStatus}`: the verification status using the correct keywords for posting to the the [Bitbucket commit status API](https://developer.atlassian.com/server/bitbucket/how-tos/updating-build-status-for-commits/).
* `${pactbroker.pactUrl}`: the "permalink" URL to the newly published pact (the URL specifying the consumer version URL, rather than the "/latest" format.)
* `${pactbroker.verificationResultUrl}`: the URL to the relevant verification result.

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

<a name="whitelist"></a>
### Webhook Whitelist

To ensure that webhooks cannot be used maliciously to expose either data about your contracts or your internal network, the following validation rules are applied to webhooks via the Pact Broker [webhook whitelist configuration settings](https://github.com/pact-foundation/pact_broker/wiki/Configuration#webhook-whitelists) .

* **Scheme**: Must be included in the `webhook_scheme_whitelist`, which by default only includes `https`. You can change this to include `http` if absolutely necessary, however, keep in mind that the body of any http traffic is visible to the network. You can load a self signed certificate into the Pact Broker to be used for https connections using [script/insert-self-signed-certificate-from-url.rb](https://github.com/pact-foundation/pact_broker/blob/master/script/insert-self-signed-certificate-from-url.rb) in the
Pact Broker Github repository.

* **HTTP method**: Must be included in the `webhook_http_method_whitelist`, which by default only includes `POST`. It is highly recommended that only `POST` requests are allowed to ensure that webhooks cannot be used to retrieve sensitive information from hosts within the same network.

* **Host**: If the `webhook_host_whitelist` contains any entries, the host must match one or more of the entries. By default, it is empty. For security purposes, if the host whitelist is empty, the response details will not be logged to the UI (though they can be seen in the application logs at debug level).

  The host whitelist may contain hostnames (eg `"github.com"`), domains beginning with `*` (eg. `"*.foo.com"`), IPs (eg `"192.0.345.4"`), network ranges (eg `"10.0.0.0/8"`) or regular expressions (eg `/.*\.foo\.com$/`). Note that IPs are not resolved, so if you specify an IP range, you need to use the IP in the webhook URL. If you wish to allow webhooks to any host (not recommended!), you can set `webhook_host_whitelist` to `[/.*/]`. Beware of any sensitive endpoints that may be exposed within the same network.

  The recommended set of values to start with are:

    * your CI server's hostname (for triggering builds)
    * your company chat (eg. Slack, for publishing notifications)
    * your code repository (eg. Github, for sending commit statuses)

  Alternatively, you could use a domain beginning with a `*` to limit requests to your company's domain.

  Note that the hostname/domain matching follows that used for SSL certificate hostnames, so `*.foo.com` will match `a.foo.com` but not `a.b.foo.com`. If you need more flexible matching because you have domains with variable "parts" (eg `a.b.foo.com`), you can use a regular expression (eg `/.*\.foo\.com$/` - don't forget the end of string anchor). You can test Ruby regular expressions at [rubular.com](http://rubular.com).

### Testing

To test a webhook, navigate to the webhook in the HAL browser, then make a POST request to the "pb:execute" relation. The latest matching pact/verification will be used in the template, or a placeholder if none exists. The response or error will be shown in the window.

### Deleting

Send a DELETE request to the webhook URL.

### Updating

Send a PUT request to the webhook URL with all fields required for the new webhook.
