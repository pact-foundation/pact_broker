# Pacticipants

"Pacticipant" - a party that participates in a pact (ie. a Consumer or a Provider).

### Creating pacticipants
Participants are created automatically when a pact is published to the pact broker. The name is based on the URL compontents used to publish the pact (ie. /pacts/provider/$PROVIDER\_NAME/consumer/$CONSUMER\_NAME/version/$CONSUMER\_VERSION), not on the contents of the pact, as the Pact Broker is designed to be agnostic of the actual pact format as much as possible.


### Deleting pacticipants
Deleting a pacticipant will delete all associated pacts, versions, tags and webhooks. To delete a pacticipant, send a DELETE request to the relevant pacticipant URL via the HAL browser.
