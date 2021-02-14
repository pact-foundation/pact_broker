# Environment

Allowed methods: `GET`, `PUT`, `DELETE`

Path: `/environment/{uuid}`

## Viewing an environment

Example:

    curl http://${PACT_BROKER_HOST}/environments/79060381-269c-4769-9894-9ec3cab44729 \
      -H "Accept: application/hal+json"
    {
      "uuid": "79060381-269c-4769-9894-9ec3cab44729",
      "name": "test",
      "displayName": "Test",
      "production": false
    }

## Updating an environment

Example:

    curl -X PUT http://${PACT_BROKER_HOST}/environments/79060381-269c-4769-9894-9ec3cab44729 \
      -H "Content-Type: application/json" \
      -H "Accept: application/hal+json" \
      -d '{
          "name": "test",
          "displayName": "Test",
          "production": false
        }'

## Deleting an environment

Example:

    curl -v -X DELETE http://${PACT_BROKER_HOST}/environments/79060381-269c-4769-9894-9ec3cab44729
