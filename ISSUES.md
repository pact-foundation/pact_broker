# Issues

## Reproducing an issue

In [script/reproduce-issue.rb](script/reproduce-issue.rb) you will find a fluent API that allows you to simulate client libraries interacting with the Pact Broker.

You can use it to easily reproduce issues.

To use it:

* Run the Pact Broker using a specific Pact Broker Docker image by setting the required tag for the pact-broker service in the docker-compose-issue-repro-with-pact-broker-docker-image.yml file.

    ```
    # might need to try twice if it doesn't connect to postgres
    docker-compose  -f docker-compose-issue-repro-with-pact-broker-docker-image.yml up pact-broker

    # if needing webhooks - new window
    docker-compose -f docker-compose-issue-repro-with-pact-broker-docker-image.yml up webhook-server

    # new window
    docker-compose -f docker-compose-issue-repro-with-pact-broker-docker-image.yml run repro-issue

    ```

* Run the reproduction script.

    ```
    docker-compose -f docker-compose-issue-repro-with-pact-broker-docker-image.yml run repro-issue
    ```

You can modify `script/reproduce-issue.rb` and then re-run it with the change applied.
