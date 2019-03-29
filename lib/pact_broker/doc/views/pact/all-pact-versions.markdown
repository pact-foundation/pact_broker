# All versions of a pact between a given consumer and provider

Allowed methods: `GET`, `DELETE`
Path: `/pacts/provider/{provider}/consumer/{consumer}/versions`

This resource returns a history of all the versions of the given pact between a consumer and provider.

## Deleting pacts

Sending a `DELETE` to this resource will delete all the pacts between the specified applications.
