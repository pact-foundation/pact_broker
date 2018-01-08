# SAAS Pact Broker

## Updating code from the open source repository

    git remote add upstream git@github.com:pact-foundation/pact_broker.git
    git pull upstream master #(or appropriate branch)
    bundle exec rake
    git push

Remember to merge the changes in to any WIP branches.

## Deploying

See the [RELEASING.md](https://github.com/DiUS/pact-broker-docker-private/blob/master/RELEASING.md) file in the pact-broker-docker-private project.
