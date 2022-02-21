# Issues

## Reproducing an issue

In [script/reproduce-issue.rb](script/reproduce-issue.rb) you will find an example fluent API script that allows you to simulate client libraries interacting with the Pact Broker.

You can use it to easily reproduce issues. You will need Docker and Docker Compose installed (but not Ruby).

To use it:

* Run the Pact Broker using a specific Pact Broker Docker image by setting the required tag for the pact-broker service in the docker-compose-issue-repro-with-pact-broker-docker-image.yml file.

    ```
    git clone git@github.com:pact-foundation/pact_broker.git
    cd pact_broker
    git checkout spike/dummy-webhooks

    docker-compose  -f docker-compose-issue-repro-with-pact-broker-docker-image.yml up pact-broker

    ```

* Run the reproduction script.

    ```
    # in a new shell
    docker-compose -f docker-compose-issue-repro-with-pact-broker-docker-image.yml run repro-issue
    ```

You can modify `script/data/dummy-webhooks.rb` and then re-run it with the change applied.
