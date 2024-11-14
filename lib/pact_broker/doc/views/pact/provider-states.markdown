# Provider States - Aggregated view by provider

Allowed methods: `GET`

Path: `/pacts/provider/{provider}/provider-states`

This resource returns a aggregated de-duplicated list of all provider states for a given provider.

Provider states are collected from the latest pact on the main branch for any dependant consumers.

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

