# Environments

Allowed methods: `GET`, `POST`

Path: `/environments`

## Creating an environment

Send a POST to `/environments` with the environment payload.

Example:

    curl http://${PACT_BROKER_HOST}/environments \
      -H "Content-Type: application/json" \
      -H "Accept: application/hal+json" \
      -d '{
          "name": "test",
          "displayName": "Test",
          "production": false
        }'

Alternatively, you can use the HAL Browser.

* Click on the `API Browser` link at the top of the Pact Broker index page.
* In the `Links` section on the left, locate the `pb:environments` relation, and click on the yellow `!` "Perform non-GET request" button.
* In the `Body:` text box, fill in the required JSON properties.
* Click `Make Request`.

Properties:

* `uuid`: System generated unique identifier.
* `name`: Must be unique. No spaces allowed. This will be the name used in the `can-i-deploy` and `record-deployment` CLI commands. eg. "payments-sit-1"
* `displayName`: A more verbose name for the environment. "Payments Team SIT 1"
* `production`: Whether or not this environment is a production environment.

If all the services in the Broker are deployed to the same "public" internet, then there only needs to be one Production environment. If there are multiple segregated production environments (eg. when maintaining on-premises software for multiple customers ) then you should create a separate production Environment for each logical deployment environment.

## Listing environments

`GET /environments`

    {
      "_embedded": {
        "environments": [
          {
            "uuid": "79060381-269c-4769-9894-9ec3cab44729",
            "name": "production",
            "displayName": "Production",
            "production": true
          }
        ]
      }
    }
