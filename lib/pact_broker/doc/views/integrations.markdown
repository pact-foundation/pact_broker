# Integrations

Path: `/integrations`

Allowed methods: `GET`, `DELETE`

Content types: `text/vnd.graphviz`, `application/hal+json`

A list of all the integrations (consumer/provider pairs) stored in the Pact Broker.

Sending a `DELETE` request to this endpoint will remove all data irretrievably from the Pact Broker.

Path: `/integrations/provider/{providerName}/consumer/{consumerName}`

Allowed methods: `DELETE`

Sending a `DELETE` request to this endpoint will remove all data irretrievably from the Pact Broker for the specified integration.