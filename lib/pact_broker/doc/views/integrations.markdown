# Integrations

Allowed methods: `GET`, `DELETE`

Path: `/integrations`

Content types: `text/vnd.graphviz`, `application/hal+json`

A list of all the integrations (consumer/provider pairs) stored in the Pact Broker.

Sending a `DELETE` request to this endpoint will remove all data irretrievably from the Pact Broker.
