# Pact Broker

The Pact Broker provides a repository for pacts created using the pact gem. When a consumer CI build is configured to publish its pacts to a Pact Broker, it allows the provider to always be verified against the latest version of the pact. Once the required development work has been done, it will also allow providers to be verified against the "production" version of a pact, giving confidence when deploying that a new version of a provider will work against the production version of a consumer.

It provides endpoints for the following:

* Publish a pact between a provider and a given version of a consumer.
* Retrieve the latest pact between a consumer and a provider.
* View a list of published pacts.
* View a list of "pacticipants" (consumers and providers).

### Upcoming development

* Create a UI to show a network diagram based on the published pacts.
* Display pacts in HTML format.
* Allow "tagging" of pacts so that the provider can be verified against the production version of a pact.

## Usage

Copy the [example](/example) directory to your workstation.
Modify the config.ru and Gemfile as desired (eg. choose database driver gem)
Run `bundle`
Run `bundle exec rackup`
Open [http://localhost:9292](http://localhost:9292) and you should see the HAL browser.

For production usage, use a web application server like Phusion Passenger to serve the Pact Broker application.
