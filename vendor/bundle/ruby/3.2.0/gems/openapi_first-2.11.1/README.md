# openapi_first

openapi_first is a Ruby gem for request / response validation and contract-testing against an [OpenAPI](https://www.openapis.org/) 3.0 or 3.1 Openapi API description (OAD). It makes an APIFirst workflow easy and reliable.

## Usage

Use an OAD to validate incoming requests:
```ruby
use OpenapiFirst::Middlewares::RequestValidation, 'openapi/openapi.yaml'
```

Turn your request tests into [contract tests](#contract-testing) against an OAD:
```ruby
# spec_helper.rb
require 'openapi_first'
OpenapiFirst::Test.setup do |config|
  config.register('openapi/openapi.yaml')
end

require 'my_app'
RSpec.configure do |config|
  config.include OpenapiFirst::Test::Methods[MyApp], type: :request
end
```

## Contents

<!-- TOC -->

- [Rack Middlewares](#rack-middlewares)
  - [Request validation](#request-validation)
  - [Response validation](#response-validation)
- [Contract testing](#contract-testing)
  - [Test assertions](#test-assertions)
- [Manual use](#manual-use)
- [Framework integration](#framework-integration)
- [Configuration](#configuration)
- [Hooks](#hooks)
- [Alternatives](#alternatives)
- [Frequently Asked Questions](#frequently-asked-questions)
- [Development](#development)
  - [Benchmarks](#benchmarks)
  - [Contributing](#contributing)

<!-- /TOC -->

## Rack Middlewares

### Request validation

The request validation middleware returns a 4xx if the request is invalid or not defined in the API description. It adds a request object to the current Rack environment at `env[OpenapiFirst::REQUEST]` with the request parameters parsed exactly as described in your API description plus access to meta information from your API description. See _[Manual use](#manual-use)_ for more details about that object.

```ruby
use OpenapiFirst::Middlewares::RequestValidation, 'openapi.yaml'

# Pass `raise_error: true` to raise an error if request is invalid:
use OpenapiFirst::Middlewares::RequestValidation, 'openapi.yaml', raise_error: true
```

#### Error responses

openapi_first produces a useful machine readable error response that can be customized.
The default response looks like this. See also [RFC 9457](https://www.rfc-editor.org/rfc/rfc9457).

```json
http-status: 400
content-type: "application/problem+json"

{
  "title": "Bad Request Body",
  "status": 400,
  "errors": [
    {
      "message": "value at `/data/name` is not a string",
      "pointer": "/data/name",
      "code": "string"
    },
    {
      "message": "number at `/data/numberOfLegs` is less than: 2",
      "pointer": "/data/numberOfLegs",
      "code": "minimum"
    },
    {
      "message": "object at `/data` is missing required properties: mandatory",
      "pointer": "/data",
      "code": "required"
    }
  ]
}
```

openapi_first offers a [JSON:API](https://jsonapi.org/) error response by passing `error_response: :jsonapi`:

```ruby
use OpenapiFirst::Middlewares::RequestValidation, 'openapi.yaml, error_response: :jsonapi'
```

<details>
<summary>See details of JSON:API error response</summary>

```json
// http-status: 400
// content-type: "application/vnd.api+json"

{
  "errors": [
    {
      "status": "400",
      "source": {
        "pointer": "/data/name"
      },
      "title": "value at `/data/name` is not a string",
      "code": "string"
    },
    {
      "status": "400",
      "source": {
        "pointer": "/data/numberOfLegs"
      },
      "title": "number at `/data/numberOfLegs` is less than: 2",
      "code": "minimum"
    },
    {
      "status": "400",
      "source": {
        "pointer": "/data"
      },
      "title": "object at `/data` is missing required properties: mandatory",
      "code": "required"
    }
  ]
}
```

</details>

#### Custom error responses

You can build your own custom error response with `error_response: MyCustomClass` that implements `OpenapiFirst::ErrorResponse`.
You can define custom error responses globally by including / implementing `OpenapiFirst::ErrorResponse` and register it via `OpenapiFirst.register_error_response(my_name, MyCustomErrorResponse)` and set `error_response: my_name`.

### Response validation

This middleware raises an error by default if the response is not valid.
This can be useful in a test or staging environment, especially if you are adopting OpenAPI for an existing implementation.

```ruby
use OpenapiFirst::Middlewares::ResponseValidation, 'openapi.yaml' if ENV['RACK_ENV'] == 'test'

# Pass `raise_error: false` to not raise an error:
use OpenapiFirst::Middlewares::ResponseValidation, 'openapi.yaml', raise_error: false
```

If you are adopting OpenAPI you can use these options together with [hooks](#hooks) to get notified about requests/responses that do match your API description.

## Contract Testing

You can see your OpenAPI API description as a contract that your clients can rely on as how your API behaves. There are two aspects of contract testing: Validation and Coverage. By validating requests and responses, you can avoid that your API implementation processes requests or returns responses that don't match your API description. To make sure your _whole_ API description is implemented, openapi_first can check that all of your API description is covered when you test your API with [rack-test](https://github.com/rack/rack-test).

Here is how to set it up:

1. Register all OpenAPI documents to track coverage for.
  This should go at the top of your test helper file before loading your application code.
    ```ruby
    require 'openapi_first'
    OpenapiFirst::Test.setup do |config|
      config.register('openapi/openapi.yaml')
    end
    ```
2. Observe your application. You can do this in multiple ways:
    - Add an `app` method to your tests (which is called by rack-test) that wraps your application with silent request / response validation.
      ```ruby
      module RequestSpecHelpers
        def app
          OpenapiFirst::Test.app(MyApp)
        end
      end

      RSpec.configure do |config|
        config.include RequestSpecHelpers, type: :request
      end
      ```

      Or do this by creating a Module and including it to add an "app" method.

      ```ruby
      RSpec.configure do |config|
        config.include OpenapiFirst::Test::Methods[MyApp], type: :request
      end
      ```
4. Run your tests. The Coverage feature will tell you about missing or invalid requests/responses:
      ```
      ✓ GET /stations
        ✓ 200(application/json)
        ❌ 200(application/xml) – No responses tracked!
        ❌ 400(application/problem+json) – No responses tracked!
      ```

      Now add tests for all those "❌" to make them "✓" and you're green!

> [!NOTE]
> Check out [faraday-openapi](https://codeberg.org/ahx/faraday-openapi) to have your API _client_ validate request/responses against an OAD, which is useful to validate HTTP mocks during testing.

### Configure test coverage

OpenapiFirst::Test raises an error when a response status is not defined. You can deactivate this with:

```ruby
OpenapiFirst::Test.setup do |test|
  [403, 401].each { test.ignored_unknown_status << it }
end
```

Exclude certain _responses_ from coverage with `skip_coverage`:

```ruby
OpenapiFirst::Test.setup do |test|
  # …
  test.skip_response_coverage do |response_definition|
    response_definition.status == '5XX'
  end
end
```

Skip coverage for a request and all responses alltogether of a route with `skip_coverage`:

```ruby
OpenapiFirst::Test.setup do |test|
  # …
  test.skip_coverage do |path, request_method|
    path == '/bookings/{bookingId}' && requests_method == 'DELETE'
  end
end
```

OpenapiFirst::Test raises an error when a request is not defined. You can deactivate this with:

```ruby
OpenapiFirst::Test.setup do |test|
  # …
  test.ignore_unknown_requests = true
end
```

### Test assertions

openapi_first ships with a simple but powerful Test method to run request and response validation in your tests without using the middlewares. This is designed to be used with rack-test or Ruby on Rails integration tests or request specs.

Here is how to set it up for Rails integration tests:

Inside your test:
```ruby
# test/integration/trips_api_test.rb
require 'test_helper'

class TripsApiTest < ActionDispatch::IntegrationTest
  include OpenapiFirst::Test::Methods

  test 'GET /trips' do
    get '/trips',
        params: { origin: 'efdbb9d1-02c2-4bc3-afb7-6788d8782b1e', destination: 'b2e783e1-c824-4d63-b37a-d8d698862f1d',
                  date: '2024-07-02T09:00:00Z' }

    assert_api_conform(status: 200)
    # assert_api_conform(status: 200, api: :v1) # Or this if you have multiple API descriptions
  end
end
```

## Manual use

Load the API description:

```ruby
require 'openapi_first'

definition = OpenapiFirst.load('openapi.yaml')
```

### Validate request

```ruby
validated_request = definition.validate_request(rack_request)

# Inspect the request and access parsed parameters
validated_request.valid?
validated_request.invalid?
validated_request.error # => Failure object or nil
validated_request.parsed_body # => The parsed request body (Hash)
validated_request.parsed_query # A Hash of query parameters that are defined in the API description, parsed exactly as described.
validated_request.parsed_path_parameters
validated_request.parsed_headers
validated_request.parsed_cookies
validated_request.parsed_params # Merged parsed path, query parameters and request body
# Access the Openapi 3 Operation Object Hash
validated_request.operation['x-foo']
validated_request.operation['operationId'] => "getStuff"
# or the whole request definition
validated_request.request_definition.path # => "/pets/{petId}"
validated_request.request_definition.operation_id # => "showPetById"

# Or you can raise an exception if validation fails:
definition.validate_request(rack_request, raise_error: true) # Raises OpenapiFirst::RequestInvalidError or OpenapiFirst::NotFoundError if request is invalid
```

### Validate response

```ruby
validated_response = definition.validate_response(rack_request, rack_response)

# Inspect the response and access parsed parameters and
validated_response.valid?
validated_response.invalid?
validated_response.error # => Failure object or nil
validated_response.status # => 200
validated_response.parsed_body
validated_response.parsed_headers

# Or you can raise an exception if validation fails:
definition.validate_response(rack_request,rack_response, raise_error: true) # Raises OpenapiFirst::ResponseInvalidError or OpenapiFirst::ResponseNotFoundError
```

## Configuration

You can configure default options globally:

```ruby
OpenapiFirst.configure do |config|
  # Specify which plugin is used to render error responses returned by the request validation middleware (defaults to :default)
  config.request_validation_error_response = :jsonapi
  # Configure if the request validation middleware should raise an exception (defaults to false)
  config.request_validation_raise_error = true
end
```

or configure per instance:

```ruby
OpenapiFirst.load('openapi.yaml') do |config|
  config.request_validation_error_response = :jsonapi
end
```

## Hooks

You can integrate your code at certain points during request/response validation via hooks.

Available hooks:

- `after_request_validation`
- `after_response_validation`
- `after_request_parameter_property_validation`
- `after_request_body_property_validation`

Setup per per instance:

```ruby
OpenapiFirst.load('openapi.yaml') do |config|
  config.after_request_validation do |validated_request|
    validated_request.valid? # => true / false
  end
  config.after_response_validation do |validated_response, request|
    if validated_response.invalid?
      warn "#{request.request_method} #{request.path}: #{validated_response.error.message}"
    end
  end
end
```

Setup globally:

```ruby
OpenapiFirst.configure do |config|
  config.after_request_parameter_property_validation do |data, property, property_schema|
    data[property] = Date.iso8601(data[property]) if property_schema['format'] == 'date'
  end
end
```

## Framework integration

Using rack middlewares is supported in probably all Ruby web frameworks.
If you are using Ruby on Rails for example, you can add the request validation middleware globally in `config/application.rb` or inside specific controllers.

The contract testing feature is designed to be used via rack-test, which should be compatible all Ruby web frameworks as well.

That aside, closer integration with specific frameworks like Sinatra, Hanami, Roda or Rails would be great. If you have ideas, pain points or PRs, please don't hesitate to [share](https://github.com/ahx/openapi_first/discussions).

## Alternatives

This gem was inspired by [committee](https://github.com/interagent/committee) (Ruby) and [Connexion](https://github.com/spec-first/connexion) (Python).
Here is a [feature comparison between openapi_first and committee](https://gist.github.com/ahx/1538c31f0652f459861713b5259e366a).

## Frequently Asked Questions

### How can I adapt request paths that don't match my schema?

Let's say you have `openapi.yaml` like this:

```yaml
servers:
  - url: https://yourhost/api
paths:
  # The actual endpoint URL is https://yourhost/api/resource
  /resource:
```

Here your OpenAPI schema defines endpoints starting with `/resource` but your actual application is mounted at `/api/resource`. You can bridge the gap by transforming the path via the `path:` configuration:

```ruby
oad = OpenapiFirst.load('openapi.yaml') do |config|
  config.path = ->(req) { request.path.delete_prefix('/api') }
end
use OpenapiFirst::Middlewares::RequestValidation, oad
```

## Development

Run `git submodule update --init` to initialize the git submodules.

Run `bin/setup` to install dependencies.

See `bundle exec rake` to run the linter and the tests.

Run `bundle exec rspec` to run the tests only.

### Benchmarks

[Results](https://gist.github.com/ahx/e6ffced58bd2e8d5baffb2f4d2c1f823)

Run benchmarks:

```sh
cd benchmarks
bundle
bundle exec ruby benchmarks.rb
```

### Contributing

If you have a question or an idea or found a bug, don't hesitate to create an issue [on Github](https://github.com/ahx/openapi_first) or [Codeberg](https://codeberg.org/ahx/openapi_first) or say hi on [Mastodon (ruby.social)](https://ruby.social/@ahx).

Pull requests are very welcome as well, of course. Feel free to create a "draft" pull request early on, even if your change is still work in progress. 🤗
