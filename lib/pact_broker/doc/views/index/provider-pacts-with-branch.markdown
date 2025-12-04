# Provider pacts with consumer branch

Allowed methods: `GET`

Path: `/pacts/provider/{provider}/branch/{branch}`

Given a pacticipant name and a consumer branch, this resource returns all the pact versions for all consumers of this provider with the specified consumer branch. For most use cases, the `latest-provider-pacts-with-branch` relation will better serve consumer needs by only returning the latest pact version for specified consumer branches.
