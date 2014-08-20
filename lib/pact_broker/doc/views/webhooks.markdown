# Webhooks

### Creating

1. To create a webhook, in the HAL Browser, navigate to the pact you want to create the webhook for
(Click "Go to Entry Point", then select "latest-pacts", then select the pact you want to create the webhook for.)
2. Click the "NON-GET" button for the "pact-webhooks" relation.
3. Paste in the webhook JSON (example shown below) in the body section and click "Make Request".

An example webhook to trigger a Bamboo job.

    {
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
      "request": {
        "method": "POST",
        "url": "http://example.org/something",
        "body": {
          "some" : "json"
        }
      }
    }

**BEWARE** The password can be reverse engineered from the database, so make a separate account for the Pact Broker to use, don't use your personal account!

### Testing

To test a webhook, navigate to the webhook in the HAL browser, then make a POST request to the "execute" relation. The response or error will be shown in the window.

### Deleting

Send a DELETE request to the webhook URL.

### Updating

Currently not implemented. You will need to delete and re-create the webhook.
