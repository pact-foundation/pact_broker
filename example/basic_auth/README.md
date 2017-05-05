# Example of Pact Broker configuration on heroku with basic authentication

## Create your Pact Broker project

```
$ mkdir my-pact-broker
$ cd my-pact-broker
$ git init
```

Then copy the files `Gemfile`, `Procfile` and `config.ru` into your project and run bundle
```
$ bundle
$ gid add .
$ git commit -m "Initial commit"
```

It's now time to deploy to heroku! Assuming you already have an account, you need to create a new application with a postgres add-on:
```
$ gem install heroku
$ heroku create
$ heroku addons:add heroku-postgresql
$ heroku config:set PACT_BROKER_USERNAME=admin
$ heroku config:set PACT_BROKER_PASSWORD=changeme
$ git push heroku master
```
Your Pact Broker instance is now available!

## Publish consumer pacts - consumer side
You will need to set these environment variables with your basic auth credentials 
```
export PACT_BROKER_USERNAME=admin
export PACT_BROKER_PASSWORD=changeme
rake pact:publish
```

## Verify pacts - provider side
In your pact_helper.rb file, you need to specify the basic auth credentials in the pact uris
```ruby
pact_uri URI.encode("http://#{ENV['PACT_BROKER_USERNAME']}:#{ENV['PACT_BROKER_PASSWORD']}@my-pact-broker.herokuapp.com/pacts/provider_pact_endpoint")
```

Enjoy!
