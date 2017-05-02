# Publish pact verification result

Allowed methods: POST

Use the `pb:publish-verification-results` link in the pact resource to publish the result (either success or failure) of a pact verification. The body of the request must include the success (true or false) and the provider application version that the pact was verified against. It may also include the build URL to facilitate debugging when failures occur.

    POST http://broker/pacts/provider/Foo/consumer/Bar/pact-version/1234
    {
      success: true,
      providerApplicationVersion: "4.5.6",
      buildUrl: "http://my-ci.org/build/3456"
    }

Multiple verification results may be published for the same pact resource.
