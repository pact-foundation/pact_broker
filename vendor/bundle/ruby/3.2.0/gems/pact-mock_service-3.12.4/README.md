
# Pact Mock and Stub Service

[![Build Status](https://github.com/pact-foundation/pact-mock_service/actions/workflows/test.yml/badge.svg)](https://github.com/pact-foundation/pact-mock_service/actions/workflows/test.yml)

This codebase provides the HTTP mock and stub service used by implementations of [Pact][pact]. It is packaged as a gem, and as a standalone executable for Mac OSX and Linux and Windows.

The mock service provides the following endpoints:

* DELETE /interactions - clear previously mocked interactions
* POST /interactions - set up an expected interaction
* PUT /interactions - clear and set up multiple expected interactions in one call
* GET /interactions/verification - determine whether the expected interactions have taken place
* POST /pact - write the pact file
* GET / - the healthcheck endpoint

All requests to the "administration" endpoints listed above must contain the header `X-Pact-Mock-Service: true` to allow the mock service to know whether the request is an administration request or a request from the actual consumer code.

As the Pact mock service can be used as a standalone executable and administered via HTTP, it can be used for testing with any language. All that is required is a library in the native language to create the HTTP calls listed above. Check out [docs.pact.io](https://docs.pact.io) for a list of implemented languages. If you are interested in creating bindings in a new language, have a chat to one of us on the [pact slack group][slack].

## Installation

### Without Ruby

Use the Pact standalone [executables][executables].

### With Ruby

Use the [pact][pact] gem if you would like the full Pact DSL, mock service and verification functionality in your ruby project.

Otherwise:

    $ gem install pact-mock_service
    $ pact-mock-service --consumer Foo --provider Bar --port 1234

Or add `gem "pact-mock_service"` to your Gemfile then run:

    $ bundle install
    $ bundle exec pact-mock-service --consumer Foo --provider Bar --port 1234

Run `pact-mock-service help` for command line options.

## Mock Service Usage

Each mock service process is designed to mock only ONE provider for ONE consumer. To mock multiple providers, you will need to start a process for each provider. The lifecycle of a mock service instance during a test suite execution is as follows:

* _Before suite:_ start mock service
* _Before each test:_ clear interactions from previous test
* _During test:_ set up interactions, execute interactions
* _After each test:_ verify interactions
* _After suite:_ write pact file, stop mock service

Each mock service instance can only handle one test process/thread at a time. If you wish to run multiple test threads in parallel, you will need to start each mock service instance on a different port, and set the `--pact-file-write-mode` to `merge` (see usage notes below).

```
Usage:
  pact-mock-service service

Options:
      [--consumer=CONSUMER]                                      # Consumer name
      [--provider=PROVIDER]                                      # Provider name
  -p, [--port=PORT]                                              # Port on which to run the service
  -h, [--host=HOST]                                              # Host on which to bind the service
                                                                 # Default: localhost
  -d, [--pact-dir=PACT_DIR]                                      # Directory to which the pacts will be written
  -m, [--pact-file-write-mode=PACT_FILE_WRITE_MODE]              # `overwrite` or `merge`. Use `merge` when running multiple mock service instances in parallel for the same consumer/provider pair. Ensure the pact file is deleted before running tests when using this option so that interactions deleted from the code are not maintained in the file.
                                                                 # Default: overwrite
  -i, [--pact-specification-version=PACT_SPECIFICATION_VERSION]  # The pact specification version to use when writing the pact
                                                                 # Default: 2
  -l, [--log=LOG]                                                # File to which to log output
  -o, [--cors=CORS]                                              # Support browser security in tests by responding to OPTIONS requests and adding CORS headers to mocked responses
      [--ssl], [--no-ssl]                                        # Use a self-signed SSL cert to run the service over HTTPS
      [--sslcert=SSLCERT]                                        # Specify the path to the SSL cert to use when running the service over HTTPS
      [--sslkey=SSLKEY]                                          # Specify the path to the SSL key to use when running the service over HTTPS

Start a mock service. If the consumer, provider and pact-dir options are provided, the pact will be written automatically on shutdown (INT).
```

See [script/example.sh](script/example.sh) for an executable example.

You can find more documentation for the mock service in the repository [wiki][wiki].

### With SSL

If you need to use the mock service with HTTPS, you can use the built-in SSL mode which relies on and generates a self-signed certificate.

    $ pact-mock-service --port 1234 --ssl

If you need to provide your own certificate and key, use the following syntax.

    $ pact-mock-service --port 1234 --ssl --sslcert PATH_TO_CERT --sslkey PATH_TO_KEY

### With CORS

Read the wiki page on [CORS][cors].

## Stub Service Usage

The pact-stub-service allows you to reuse interactions that have been generated in previous tests. The typical situation would be to generate your pact file using unit tests, and then use the pact stub service for your higher level integration/ui tests. To help reduce the number of interactions that need verifying, you will want to use flexible matching on both requests and responses.

Unlike the mock service, which has a Ruby DSL for managing its lifecycle, the mock service can currently only be started from the command line, so you will need to start/background/kill the process yourself. If this is causing problems, please raise it in the pact slack group and we can discuss potential enhancements.

```
Usage:
  pact-stub-service PACT_URI ...

Options:
  -p, [--port=PORT]        # Port on which to run the service
  -h, [--host=HOST]        # Host on which to bind the service
                           # Default: localhost
  -l, [--log=LOG]          # File to which to log output
  -o, [--cors=CORS]        # Support browser security in tests by responding to OPTIONS requests and adding CORS headers to mocked responses
      [--ssl], [--no-ssl]  # Use a self-signed SSL cert to run the service over HTTPS
      [--sslcert=SSLCERT]  # Specify the path to the SSL cert to use when running the service over HTTPS
      [--sslkey=SSLKEY]    # Specify the path to the SSL key to use when running the service over HTTPS

Description:
  Start a stub service with the given pact file(s). Pact URIs may be local file paths or HTTP.
  Include any basic auth details in the URL using the format https://USERNAME:PASSWORD@URI.
  Where multiple matching interactions are found, the interactions will be sorted by
  response status, and the first one will be returned. This may lead to some non-deterministic
  behaviour. If you are having problems with this, please raise it on the pact slack group,
  and we can discuss some potential enhancements.
  Note that only versions 1 and 2 of the pact specification are currently fully supported.
  Pacts using the v3 format may be used, however, any matching features added in v4 will
  currently be ignored.
```

## Contributing

See [CONTRIBUTING.md](/CONTRIBUTING.md)

[pact]: https://github.com/pact-foundation/pact-ruby
[executables]: https://github.com/pact-foundation/pact-ruby-standalone/releases
[slack]: https://slack.pact.io
[wiki]: https://github.com/pact-foundation/pact-mock_service/wiki
[cors]: https://github.com/pact-foundation/pact-mock_service/wiki/Using-the-mock-service-with-CORS
