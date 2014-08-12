# Webhooks

## Creating

1. To create a webhook, navigate to the pact you want to create the webhook for
(Click "Go to Entry Point", then select "latest-pacts", then select the pact you want to create the webhook for.)
2. Click the "NON-GET" button for the "pact-webhooks" relation.
3. Paste in the webhook JSON (example shown below) in the body section and click "Make Request".

An example webhook to trigger a Bamboo job.

    {
      "request": {
        "method": "POST",
        "url": "http://master.ci.my.domain:8085/rest/api/latest/queue/SOME-PROJECT?os_authType=basic",
        "headers": {
          "Authorization": "Basic dXNlcm5hbWU6cGFzc3dvcmQ="
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

To create an Authorisation header, run:

    ruby -e "require 'base64'; puts ('Basic ' + Base64.strict_encode64('your-username:your-password'))"

## Testing

To test a webhook, navigate to the webhook in the HAL browser, then make a POST request to the "execute" relation. The response or error will be shown in the window.