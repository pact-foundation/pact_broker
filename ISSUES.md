# Issues

## Reproducing an issue

In [script/reproduce-issue.rb](script/reproduce-issue.rb) you will find a fluent API that allows you to simulate client libraries interacting with the Pact Broker.

You can use it to easily reproduce issues.

To use it:

* Run the Pact Broker using a specific Pact Broker Docker image by setting the required tag for the pact-broker service in the docker-compose-issue-repro-with-pact-broker-docker-image.yml file.

    ```
    docker-compose -f docker-compose-issue-repro-with-pact-broker-docker-image.yml up --build pact-broker
    ```

* Run the reproduction script.

    ```
    docker-compose -f docker-compose-issue-repro-with-pact-broker-docker-image.yml up repro-issue
    ```

You can modify `script/reproduce-issue.rb` and then re-run it with the change applied.
