# Changelog

## Unreleased

## 2.11.1

- OpenapiFirst can now route requests correctly for paths like `/stuffs` and `/stuffs{format}` (https://github.com/ahx/openapi_first/issues/386)

## 2.11.0

- OpenapiFirst::Test.observe now works with `Rack::URLMap` (returned by `Rack::Builder.app`) and probably all objects that respond to `.call`

## 2.10.1

- Don't try to track coverage for skipped requests
- Add Test::Configuration#skip_coverage to skip test coverage for specific paths + request methods and all responses
- Deprecate setting minimum_coverage value. Use skip_response_coverage, ignored_unknown_status to configure coverage instead.
- Update openapi_parameters to make parsing array query parameters more consistent.
  Now parsing empty array query parameter like `ids=&` or `ids&` both result in an empty array value (`[]`) instead of `nil` or `""`.
- Fix Test::Coverage.result returning < 100 even if plan is fully covered

## 2.10.0 (yanked)

## 2.9.3

- Fix OpenapiFirst.load when MultiJson is configured to return symbol keys

## 2.9.2

- OpenapiFirst::Test reports all non-covered requests now
- Response validation: Improve content type mismatch exception message

## 2.9.1

- Fix OpenapiFirst::Test's request validation to not always raise an error, but only for unknown requests

## 2.9.0

- OpenapiFirst::Test now raises an error for unknown requests. You can deactivate with:

```ruby
OpenapiFirst::Test.setup do |test|
  # ...
  test.ignore_unknown_request = true
end
```

- NotFoundError#message now includes the requested path

## 2.8.0

### OpenapiFirst::Test is now stricter and more configurable

Changes:
- Changed OpenapiFirst::Test to raises an "invalid response" error if it sees an invalid response (https://github.com/ahx/openapi_first/issues/366).
  You can change this back to the old behavior by setting `OpenapiFirst::Test::Configuration#response_raise_error = false` (but you shouldn't).
- Added `Test.setup { it.observe(MyApp) }`, `Test.observe(App, api: :my_api)` and internal `Test::Callable[]` to inject request/response validation in rack app as an alternative to overwrite the `app` method in a test
- Added `Test::Configuration#ignored_unknown_status` to configure response status(es) that do not have to be descriped in the API description. 404 statuses are ignored by default.
- Changed `OpenapiFirst::Test` to make tests fail if API description is not covered by tests. You can adapt this behavior via `OpenapiFirst::Test.setup` / `skip_response_coverage` or deactivate coverage with `OpenapiFirst::Test::Configuration#report_coverage = false` or `report_coverage = :warn`

## 2.7.4

- Return 400 if Rack cannot parse query string instead of raising an exception. Fixes https://github.com/ahx/openapi_first/issues/372

## 2.7.3

- Accept loading OAD documents with numeric status codes. Fixes "Unknown reference" error. https://github.com/ahx/openapi_first/issues/367

- Support QUERY request method
  OpenAPI 3.0, 3.1 does not support that, but this does

## 2.7.2

- Fix $ref-resolving for referenced arrays.
  This fixes loading something like this:
  ```yaml
  parameters:
    $ref: 'my-paramters.yaml'
  ```

## 2.7.1

- Speedup loading very large OADs by deferring creation of JSONSchemer::Schema instances.

## 2.7.0

- Allow to override path for schema matching with `config.path = ->(request) { '/prefix' + request.path  } ` (https://github.com/ahx/openapi_first/issues/349)
- Support passing in a Definition instance when registering an OAD for tests (https://github.com/ahx/openapi_first/issues/353)
- Fix registering multiple APIs for testing (https://github.com/ahx/openapi_first/issues/352)

## 2.6.0

- Middlewares now accept the OAD as a first positional argument instead of `:spec` inside the options hash.
- No longer merge parameter schemas of the same location (for example "query") in order to fix [#320](https://github.com/ahx/openapi_first/issues/320).
- `OpenapiFirst::Test::Methods[MyApplication]` returns a Module which adds an `app` method to be used by rack-test alonside the `assert_api_conform` method.
- Make default coverage report less verbose
  The default formatter (TerminalFormatter) no longer prints all un-requested requests by default. You can set `test.coverage_formatter_options = { focused: false }` to get back the old behavior

## 2.5.1

- Fix skipping skipped responses during coverage tracking

## 2.5.0

### New feature
- Add option to skip certain responses in coverage calculation
  ```ruby
  require 'openapi_first'
  OpenapiFirst::Test.setup do |s|
    test.register('openapi/openapi.yaml')
    test.skip_response_coverage { it.status == '401' }
  end
  ```

### Minor changes
- OpenapiFirst::Test.report_coverage now includes fractional digits when returning a coverage value to avoid reporting "0% / no requests made" even though some requests have been made.
- Show details about invalid requests / responses in coverage report

## 2.4.0

- Support less verbose test setup without the need to call `OpenapiFirst::Test.report_coverage`, which will be called `at_exit`:
  ```ruby
  OpenapiFirst::Test.setup do |test|
    test.register('openapi/openapi.yaml')
    test.minimum_coverage = 100 # Setting this will lead to an `exit 2` if coverage is below minimum
  end
  ```
- Add `OpenapiFirst::Test::Setup#minimum_coverage=` to control exit behaviour (exit 2 if coverage is below minimum)
- Add `verbose` option to `OpenapiFirst::Test.report_coverage(verbose: true)`
  to see all passing requests/responses

## 2.3.0

### New feature
- Add OpenapiFirst::Test::Coverage to track request/response coverage for your API descriptions. (https://github.com/ahx/openapi_first/pull/327)

## 2.2.4

- Fix request validation file uploads in multipart/form-data requests with nested fields (https://github.com/ahx/openapi_first/issues/324)
- Add more error details to validation result (https://github.com/ahx/openapi_first/pull/322)

## 2.2.3

- Respect global JSONSchemer configuration (https://github.com/ahx/openapi_first/pull/318)

## 2.2.2

- Fix parsing parameters with referenced schemas (https://github.com/ahx/openapi_first/issues/316)

## 2.2.1

- Fix issue with $ref resolving paths poiting outside directories `$ref: '../a/b.yaml'` (https://github.com/ahx/openapi_first/issues/313)
- Remove warning about missing assertions when using assert_api_conform ([https://github.com/ahx/openapi_first/issues/313](https://github.com/ahx/openapi_first/issues/312))

## 2.2.0

- Fix support for discriminator in response bodies if no mapping is defined (https://github.com/ahx/openapi_first/issues/285)
- Fix support for discriminator in request bodies if no mapping is defined
- Replace bundled json_refs fork with own code
- Better error messages when OpenAPI file has invalid references ("$ref")
- Autoload OpenapiFirst::Test module. There is no need to `require 'openapi_first/test'` anymore.
- Remove multi_json dependency. openapi_first uses multi_json if available or the default json gem otherwise.
  If you want to use multi_json, make sure to add it to your Gemfile.

## 2.1.1

- Fix issue with non file downloads / JSON responses https://github.com/ahx/openapi_first/issues/281

## 2.1.0

- Added `OpenapiFirst::Definition#[]` to access the raw Hash representation of the OAS document. Example: `api['components'].fetch('schemas', 'Stations')`

## 2.0.4

- Fix issue with parsing reponse body when using Rails https://github.com/ahx/openapi_first/issues/281

## 2.0.3

- Fix `OpenapiFirst::Test.register` https://github.com/ahx/openapi_first/issues/276

- Request validation middleware now accepts `error_response: false` do disable rendering a response. This is useful if you just want to collect metrics (via hooks) during a migration phase.

## 2.0.2

- Fix setting custom error response (thanks @gobijan)

## 2.0.1 (Janked)

## 2.0.0

### New Features
- Test Assertions! 📋 You can now use `assert_api_conform`  for contract testing in your rack-test / Rails integration tests. See Readme for details.

- New option for `Middlewares::ResponseValidation`: `:raise_error` (default: true). If set to `false`, the middleware will not aise an error if the response is invalid. 🤫

- Hooks 🪝🪝 (see Readme for details). You can use these to collect metrics, write error logs etc.:
  - `after_request_validation`
  - `after_response_validation`
  - `after_request_body_property_validation`
  - `after_request_parameter_property_validation`

- Exceptions such as `OpenapiFirst::ResponseInvalidError` not respond to `#request` to get information about the validated request 💁🏻

- Performance improvements 🚴🏻‍♀️

- Validation failures returned by `ValidatedRequest#error` always returns a `#message`. So you can call `my_validated_request.error.message if validated_request.invalid?` and always get a human-readable error message. 😴

### Breaking Changes

#### Manual validation
- `Definition#request.validate` was removed. Please use `Definition#validate_request` instead.
- `Definition#validate_request` returns a `ValidatedRequest` which delgates all methods to the original (rack) request, except for `#valid?` `#parsed_body`. `#parsed_query`, `#operation` etc. See Readme for details.
- The `Operation` class was removed. `ValidatedRequest#operation` now returns the OpenAPI 3 operation object as a plain Hash. So you can still call `ValidatedRequest#operation['x-foo']`. You can call `ValidatedRequest#operation_id` if you just need the _operationId_.
-

#### Inspecting OpenAPI files

- `Definition#operations` has been removed. Please use `Definition#routes`, which returns a list of routes. Routes have a `#path`, `#request_method`, `#requests` and `#responses`.
A route has one path and one request method, but can have multiple requests (one for each supported content-type) and responses (statuses + content-type).

- Several internal changes to make the code more maintainable, more performant , support hooks and prepare for OpenAPI 4. If you have monkey-patched OpenapiFirst, you might need to adjust your code. Please contact me if you need help.

### Deprecations

#### Custom error responses

- `ValidationError#error`, `#instance_location` and `#schema_location` have been deprecated. Use `ValidationError#message`, `#data_pointer` and `#schema_pointer` instead.
- `Failure#error_type` has been deprecated. Use `#type` instead

## 1.4.3

- Allow using json_schemer 2...3

## 1.4.2

- Fix Rack 2 compatibility

## 1.4.1

- Fixed: Don't call deprecated methods in middlewares

## 1.4.0

### Changed

Some redundant methods to validate or inspect requests/responses will be removed in 2.0. So this release deprecates these methods.

- Deprecate `OpenapiFirst::RuntimeRequest#validate`, `#validate!`, `#validate_response`, `#response`.
  Use `OpenapiFirst.load('openapi.yaml').validate_request(rack_request, raise_error: true/false)` instead
- Deprecate `OpenapiFirst::RuntimeResponse#validate`.
  Use `OpenapiFirst.load('openapi.yaml').validate_response(rack_request, rack_response, raise_error: true/false)` instead.

## 1.3.6

- Fixed Rack 2 / Rails 6 compatibility ([#246](https://github.com/ahx/openapi_first/issues/246)

## 1.3.5

- Added support for `/some/{kebab-cased}` path parameters ([#245](https://github.com/ahx/openapi_first/issues/245))

## 1.3.4

- Fixed handling "binary" format in optional multipart file uploads
- Cache the resolved OAD. This especially makes things run faster in tests.
- Internally used `Operation#query_parameters`, `Operation#path_parameters` etc. now only returns parameters that are defined on the operation level not on the PathItem. Use `PathItem#query_parameters` to get those.

## 1.3.3 (yanked)

## 1.3.2

### Changed

- The response definition is found even if the status is defined as an Integer instead of a String. This is not provided for in the OAS specification, but is often done this way, because of YAML.

### Fixed

- Reduced initial load time for composed API descriptions [#232](https://github.com/ahx/openapi_first/pull/232)
- Chore: Add Readme back to gem. Add link to docs.

## 1.3.1

- Fixed warning about duplicated constant

## 1.3.0

No breaking changes

New features:

- Added new API: `Definition#validate_request`, `Definition#validate_response`, `RuntimeRequest#validate_response` (see readme) [#222](https://github.com/ahx/openapi_first/pull/222)

Fixes:

- Manual response validation (without the middleware) just works in Rails' request tests now. [#224](https://github.com/ahx/openapi_first/pull/224)

## 1.2.0

No breaking changes

- Added `OpenapiFirst.parse(hash)` to load ("parse") a resolved/de-referenced Hash
- Added support for unescaped special characters in the path params (https://github.com/ahx/openapi_first/pull/217)
- Added `operation` to `RuntimeRequest` by [@MrBananaLord](https://github.com/ahx/openapi_first/pull/216)

## 1.1.1

- Fix reading response body for example when running Rails (`ActionDispatch::Response::RackBody`)
- Add `known?`, `status`, `body`, `headers`, `content_type` methods to inspect the parsed response (`RuntimeResponse`)
- Add `OpenapiFirst::ParseError` which is raised by low-level interfaces like `request.body` if the body could not be parsed.
- Add "code" field to errors in JSON:API error response

## 1.1.0 (yanked)

## 1.0.0

- Breaking: The default error uses application/problem+json content-type
- Breaking: Moved rack middlewares to OpenapiFirst::Middlewares
- Breaking: Rename OpenapiFirst::ResponseInvalid to OpenapiFirst::ResponseInvalidError
- Breaking: Remove OpenapiFirst::Router
- Breaking: Remove `env[OpenapiFirst::OPERATION]`. Use `env[OpenapiFirst::REQUEST]` instead.
- Breaking: Remove `env[OpenapiFirst::REQUEST_BODY]`, `env[OpenapiFirst::PARAMS]`. Use `env[OpenapiFirst::REQUEST].body env[OpenapiFirst::REQUEST].params` instead.
- Add interface to validate requests / responses without middlewares (see "Manual validation" in README)
- Add OpenapiFirst.configure
- Add OpenapiFirst.register, OpenapiFirst.plugin
- Fix response header validation with Rack 3
- Fixed: Add support for paths like `/{a}..{b}`

## 1.0.0.beta6

- Fix: Make response header validation work with rack 3
- Refactor router
  - Remove dependency hanami-router
  - PathItem and Operation for a request can be found by calling methods on the Definitnion
- Fixed https://github.com/ahx/openapi_first/issues/155
- Breaking / Regression: A paths like /pets/{from}-{to} if there is a path "/pets/{id}"

## 1.0.0.beta5

- Added: `OpenapiFirst::Config.default_options=` to set default options globally
- Added: You can define custom error responses by subclassing `OpenapiFirst::ErrorResponse` and register it via `OpenapiFirst.register_error_response(name, MyCustomErrorResponse)`

## 1.0.0.beta4

- Update json_schemer to version 2.0
- Breaking: Requires Ruby 3.1 or later
- Added: Parameters are available at `env[OpenapiFirst::PATH_PARAMS]`, `env[OpenapiFirst::QUERY_PARAMS]`, `env[OpenapiFirst::HEADER_PARAMS]`, `env[OpenapiFirst::COOKIE_PARAMS]` in case you need to access them separately. Merged path and query parameters are still available at `env[OpenapiFirst::PARAMS]`
- Breaking / Added: ResponseValidation now validates response headers
- Breaking / Added: RequestValidation now validates cookie, path and header parameters
- Breaking: multipart File uploads are now read and then validated
- Breaking: Remove OpenapiFirst.env method
- Breaking: Request validation returns 400 instead of 415 if request body is required, but empty

## 1.0.0.beta3

- Remove obsolete dependency: deep_merge
- Remove obsolete dependency: hanami-utils

## 1.0.0.beta2

- Fixed dependencies. Remove unused code.

## 1.0.0.beta1

- Removed: `OpenapiFirst::Responder` and `OpenapiFirst::RackResponder`
- Removed: `OpenapiFirst.app` and `OpenapiFirst.middleware`
- Removed: `OpenapiFirst::Coverage`
- Breaking: Parsed query and path parameters are available at `env[OpenapiFirst::PARAMS]`(or `env['openapi.params']`) instead of `OpenapiFirst::PARAMETERS`.
- Breaking: Request body and parameters now use string keys instead of symbols!
- Breaking: Query parameters are now parsed exactly like in the API description via the openapi_parameters gem. This means a couple of things:
  - Query parameters now support `explode: true` (default) and `explode: false` for array and object parameters.
  - Query parameters with brackets like 'filter[tag]' are no longer deconstructed into nested hashes, but accessible via the `filter[tag]` key.
  - Query parameters are no longer interpreted as `style: deepObject` by default. If you want to use `style: deepObject`, for example to pass a nested hash as a query parameter like `filter[tag]`, you have to set `style: deepObject` explicitly.
- Path parameters are now parsed exactly as in the API description via the openapi_parameters gem.

## 0.21.0

- Fix: Query parameter validation does not fail if header parameters are defined (Thanks to [JF Lalonde](https://github.com/JF-Lalonde))
- Update Ruby dependency to >= 3.0.5
- Handle simple form-data in request bodies (see https://github.com/ahx/openapi_first/issues/149)
- Update to hanami-router 2.0.0 stable

## 0.20.0

- You can pass a filepath to `spec:` now so you no longer have to call `OpenapiFirst.load` anymore.
- Router is optional now.
  You no longer have to add `Router` to your middleware stack. You still can add it to customize behaviour by setting options, but you no longer have to add it.
  If you don't add the Router, make sure you pass `spec:` to your request/response validation middleware.
- Support "4xx" and "4XX" response definitions.
  (4XX is defined in the standard, but 2xx is used in the wild as well 🦁.)
- Removed warning about missing operationId, because operationId is not used until the Responder is used.
- Raise HandlerNotFoundError when handler cannot be found

## 0.19.0

- Add `RackResponder`

- BREAKING CHANGE: Handler classes are now instantiated only once without any arguments and the same instance is called on each following call/request.

## 0.18.0

Yanked. No useful changes.

## 0.17.0

- BREAKING CHANGE: Use a Hash instead of named arguments for middleware options for better compatibility
  Using named arguments is actually not supported in Rack.

## 0.16.1

- Pin hanami-router version, because alpha6 is broken.

## 0.16.0

- Support status code wildcards like "2XX", "4XX"

## 0.15.0

- Populate default parameter values

## 0.14.3

- Use json_refs to resolve OpenAPI file. This removes oas_parser and ActiveSupport from list of dependencies

## 0.14.2

- Empty query parameters are parsed and request validation returns 400 if an empty string is not allowed. Note that this does not look at `allowEmptyValue` in any way, because allowEmptyValue is deprecated.

## 0.14.1

- Fix: Don't mix path- and operation-level parameters for request validation

## 0.14.0

- Handle custom x-handler field in the API description to find a handler method not based on operationId
- Add `resolver` option to provide a custom resolver to find a handler method

## 0.13.3

- Better error message if string does not match format
- readOnly and writeOnly just works when used inside allOf

## 0.13.2

- Return indicator (`source: { parameter: 'list/1' }`) in error response body when array item in query parameter is invalid

## 0.13.0

- Add support for arrays in query parameters (style: form, explode: false)
- Remove warning when handler is not implemented

## 0.12.5

- Add `not_found: :continue` option to Router to make it do nothing if request is unknown

## 0.12.4

- content-type is found while ignoring additional content-type parameters (`application/json` is found when request/response content-type is `application/json; charset=UTF8`)
- Support wildcard mime-types when finding the content-type

## 0.12.3

- Add `response_validation:`, `router_raise_error` options to standalone mode.

## 0.12.2

- Allow response to have no media type object specified

## 0.12.1

- Fix response when handler returns 404 or 405
- Don't validate the response content if status is 204 (no content)

## 0.12.0

- Change `ResponseValidator` to raise an exception if it found a problem
- Params have symbolized keys now
- Remove `not_found` option from Router. Return 405 if HTTP verb is not allowed (via Hanami::Router)
- Add `raise_error` option to OpenapiFirst.app (false by default)
- Add ResponseValidation to OpenapiFirst.app if raise_error option is true
- Rename `raise` option to `raise_error`
- Add `raise_error` option to RequestValidation middleware
- Raise error if handler could not be found by Responder
- Add `Operation#name` that returns a human readable name for an operation

## 0.11.0

- Raise error if you forgot to add the Router middleware
- Make OpenapiFirst.app raise an error in test env when request path is not specified
- Rename OperationResolver to Responder
- Add ResponseValidation middleware that validates the response body
- Add `raise` option to Router middleware to raise an error if request could not be found in the API description similar to committee's raise option.
- Move namespace option from Router to OperationResolver

## 0.10.2

- Return 400 if request body has invalid JSON ([issue](https://github.com/ahx/openapi_first/issues/73)) thanks Thomas Frütel

## 0.10.1

- Fix duplicated key in `required` when generating JSON schema for `some[thing]` parameters

## 0.10.0

- Add support for query parameters named `"some[thing]"` ([issue](https://github.com/ahx/openapi_first/issues/40))

## 0.9.0

- Make request validation usable standalone

## 0.8.0

- Add merged parameter and request body available to env at `env[OpenapiFirst::INBOX]` in request validation
- Path and query parameters with `type: boolean` now get converted to `true`/`false`
- Rename `OpenapiFirst::PARAMS` to `OpenapiFirst::PARAMETERS`

## 0.7.1

- Add missing `require` to work with new version of `oas_parser`

## 0.7.0

- Make use of hanami-router, because it's fast
- Remove option `allow_unknown_query_paramerters`
- Move the namespace option to Router
- Convert numeric path and query parameters to `Integer` or `Float`
- Pass the Rack env if your action class' initializers accepts an argument
- Respec rack's `env['SCRIPT_NAME']` in router
- Add MIT license

## 0.6.10

- Bugfix: params.env['unknown'] now returns `nil` as expected. Thanks @tristandruyen.

## 0.6.9

- Removed radix tree, because of a bug (https://github.com/namusyaka/r2ree-ruby/issues/2)

## 0.6.8

- Performance: About 25% performance increase (i/s) with help of c++ based radix-tree and some optimizations
- Update dependencies

## 0.6.7

- Fix: version number of oas_parser

## 0.6.6

- Remove warnings for Ruby 2.7

## 0.6.5

- Merge QueryParameterValidation and ReqestBodyValidation middlewares into RequestValidation
- Rename option to `allow_unknown_query_paramerters`

## 0.6.4

- Fix: Rewind request body after reading

## 0.6.3

- Add option to parse only certain paths from OAS file

## 0.6.2

- Add support to map operationIds like `things#index` or `web.things_index`

## 0.6.1

- Make ResponseValidator errors easier to read

## 0.6.0

- Set the content-type based on the OpenAPI description [#29](https://github.com/ahx/openapi-first/pull/29)
- Add CHANGELOG 📝
