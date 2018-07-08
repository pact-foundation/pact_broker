# Publish pact verification result

Allowed methods: `POST`

Use a `POST` request to the `pb:publish-verification-results` link (`$['_links']['pb:publish-verification-results']['href']`) in the pact resource to publish the result (either success or failure) of a pact verification. The body of the request must include the success (true or false) and the provider application version that the pact was verified against. It may also include the build URL to facilitate debugging when failures occur.

    {
      "success": true,
      "providerApplicationVersion": "4.5.6",
      "buildUrl": "http://my-ci.org/build/3456"
    }

Multiple verification results may be published for the same pact resource. The most recently published one will be considered to reflect the current status of verification.
