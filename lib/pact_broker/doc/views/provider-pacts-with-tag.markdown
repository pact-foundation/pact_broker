# Provider pacts

Allowed methods: `GET`

Given a pacticipant name and a consumer version tag, this resource returns all the pact versions for all consumers of this provider with the specified tag. The most common use of this resource is to find all the `production` pact versions for the mobile consumers of an API, so that backwards compatibility can be maintained.
