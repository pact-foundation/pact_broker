# openapi_parameters

openapi_parameters is an an [OpenAPI](https://www.openapis.org/) aware parameter parser.

openapi_parameters unpacks HTTP/Rack query / path / header / cookie parameters exactly as described in an [OpenAPI](https://www.openapis.org/) definition. It supports `style`, `explode` and `schema` definitions according to OpenAPI 3.1 (or 3.0). The gem is mainly build to be used inside of other OpenAPI tooling like [openapi_first](https://github.com/ahx/openapi_first).

[Learn about parameters in OpenAPI](https://spec.openapis.org/oas/latest.html#parameter-object).

## Synopsis

Note that OpenAPI supportes parameter definition on path and operation objects. Parameter definitions must use strings as keys.

### Unpack query/path/header/cookie parameters from HTTP requests according to their OpenAPI definition

```ruby

query_parameters = OpenapiParameters::Query.new([{
  'name' => 'ids',
  'required' => true,
  'in' => 'query', # Note that we only pass query parameters here
  'schema' => {
    'type' => 'array',
    'items' => {
      'type' => 'integer'
    }
  }
}])
query_string = env['QUERY_STRING'] # => 'ids=1&ids=2'
query_parameters.unpack(query_string) # => { 'ids' => [1, 2] }

# Find unknown query parameters
# Note that this does only return unknown top-level values 
query_parameters.unknown_values('ids=1&ids=2&foo=bar') # => { 'foo' => 'bar' }

path_parameters = OpenapiParameters::Path.new(parameters)
route_params = env['route.params'] # This depends on the webframework you are using
path_parameters.unpack(route_params) # => { 'ids' => [1, 2, 3] }

header_parameters = OpenapiParameters::Header.new(parameters)
header_parameters.unpack_env(env)

cookie_parameters = OpenapiParameters::Cookie.new(parameters)
cookie_string = env['HTTP_COOKIE'] # => "ids=3"
cookie_parameters.unpack(cookie_string) # => { 'ids' => [3] }
```

Note that this library does not validate the parameter value against it's JSON Schema.

### Inspect parameter definition

```ruby
parameter = OpenapiParameters::Parameter.new({
  'name' => 'ids',
  'required' => true,
  'in' => 'query', # or 'path', 'header', 'cookie'
  'schema' => {
    'type' => 'array',
    'items' => {
      'type' => 'integer'
    }
  }
})
parameter.name # => 'ids'
parameter.required? # => true
parameter.in # => 'query'
parameter.location # => 'query' (alias for in)
parameter.schema # => { 'type' => 'array', 'items' => { 'type' => 'integer' } }
parameter.type # => 'array'
parameter.deprecated? # => false
parameter.media_type # => nil
parameter.allow_reserved? # => false
# etc.
```

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add openapi_parameters

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install openapi_parameters

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ahx/openapi_parameters.
