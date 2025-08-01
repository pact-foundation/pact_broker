# Provider States - Aggregated view by provider

Allowed methods: `GET`

This resource returns a aggregated de-duplicated list of all provider states for a given provider.

Path: `/pacts/provider/{provider}/provider-states`

Provider states are collected from the latest pact on the main branch for any dependant consumers.

Path: `/pacts/provider/{provider}/provider-states/branch/{branch_name}`

Provider states are collected from the latest pacts on the specified branch for any dependant consumers.

Path: `/pacts/provider/{provider}/provider-states/environment/{environment_name}`

Provider states are collected from the latest pacts in the specified environment for any dependant consumers.

Example response

```json
{
    "providerStates": [
        {
            "name": "an error occurs retrieving an alligator"
        },
        {
            "name": "there is an alligator named Mary"
        },
        {
            "name": "there is not an alligator named Mary"
        }
    ]
}
```
