# JSONSchemer

JSON Schema validator. Supports drafts 4, 6, 7, 2019-09, 2020-12, OpenAPI 3.0, and OpenAPI 3.1.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'json_schemer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install json_schemer

## Usage

```ruby
require 'json_schemer'

schema = {
  'type' => 'object',
  'properties' => {
    'abc' => {
      'type' => 'integer',
      'minimum' => 11
    }
  }
}
schemer = JSONSchemer.schema(schema)

# true/false validation

schemer.valid?({ 'abc' => 11 })
# => true

schemer.valid?({ 'abc' => 10 })
# => false

# error validation (`validate` returns an enumerator)

schemer.validate({ 'abc' => 10 }).to_a
# => [{"data"=>10,
#      "data_pointer"=>"/abc",
#      "schema"=>{"type"=>"integer", "minimum"=>11},
#      "schema_pointer"=>"/properties/abc",
#      "root_schema"=>{"type"=>"object", "properties"=>{"abc"=>{"type"=>"integer", "minimum"=>11}}},
#      "type"=>"minimum",
#      "error"=>"number at `/abc` is less than: 11"}]

# default property values

data = {}
JSONSchemer.schema(
  {
    'properties' => {
      'foo' => {
        'default' => 'bar'
      }
    }
  },
  insert_property_defaults: true
).valid?(data)
data
# => {"foo"=>"bar"}

# schema files

require 'pathname'

schema = Pathname.new('/path/to/schema.json')
schemer = JSONSchemer.schema(schema)

# schema json string

schema = '{ "type": "integer" }'
schemer = JSONSchemer.schema(schema)

# schema validation

JSONSchemer.valid_schema?({ '$id' => 'valid' })
# => true

JSONSchemer.validate_schema({ '$id' => '#invalid' }).to_a
# => [{"data"=>"#invalid",
#      "data_pointer"=>"/$id",
#      "schema"=>{"$ref"=>"#/$defs/uriReferenceString", "$comment"=>"Non-empty fragments not allowed.", "pattern"=>"^[^#]*#?$"},
#      "schema_pointer"=>"/properties/$id",
#      "root_schema"=>{...meta schema},
#      "type"=>"pattern",
#      "error"=>"string at `/$id` does not match pattern: ^[^#]*#?$"}]

# subschemas

schema = {
  'type' => 'integer',
  '$defs' => {
    'foo' => {
      'type' => 'string'
    }
  }
}
schemer = JSONSchemer.schema(schema)

schemer.ref('#/$defs/foo').validate(1).to_a
# => [{"data"=>1,
#      "data_pointer"=>"",
#      "schema"=>{"type"=>"string"},
#      "schema_pointer"=>"/$defs/foo",
#      "root_schema"=>{"type"=>"integer", "$defs"=>{"foo"=>{"type"=>"string"}}},
#      "type"=>"string",
#      "error"=>"value at root is not a string"}]

# schema bundling (https://json-schema.org/draft/2020-12/json-schema-core.html#section-9.3)

schema = {
  '$id' => 'http://example.com/schema',
  'allOf' => [
    { '$ref' => 'schema/one' },
    { '$ref' => 'schema/two' }
  ]
}
refs = {
  URI('http://example.com/schema/one') => {
    'type' => 'integer'
  },
  URI('http://example.com/schema/two') => {
    'minimum' => 11
  }
}
schemer = JSONSchemer.schema(schema, :ref_resolver => refs.to_proc)

schemer.bundle
# => {"$id"=>"http://example.com/schema",
#     "allOf"=>[{"$ref"=>"schema/one"}, {"$ref"=>"schema/two"}],
#     "$schema"=>"https://json-schema.org/draft/2020-12/schema",
#     "$defs"=>
#      {"http://example.com/schema/one"=>{"type"=>"integer", "$id"=>"http://example.com/schema/one", "$schema"=>"https://json-schema.org/draft/2020-12/schema"},
#       "http://example.com/schema/two"=>{"minimum"=>11, "$id"=>"http://example.com/schema/two", "$schema"=>"https://json-schema.org/draft/2020-12/schema"}}}
```

## Options

```ruby
JSONSchemer.schema(
  schema,

  # meta schema to use for vocabularies (keyword behavior) and schema validation
  # String/JSONSchemer::Schema
  # 'https://json-schema.org/draft/2020-12/schema': JSONSchemer.draft202012
  # 'https://json-schema.org/draft/2019-09/schema': JSONSchemer.draft201909
  # 'http://json-schema.org/draft-07/schema#': JSONSchemer.draft7
  # 'http://json-schema.org/draft-06/schema#': JSONSchemer.draft6
  # 'http://json-schema.org/draft-04/schema#': JSONSchemer.draft4
  # 'http://json-schema.org/schema#': JSONSchemer.draft4
  # 'https://spec.openapis.org/oas/3.1/dialect/base': JSONSchemer.openapi31
  # 'json-schemer://openapi30/schema': JSONSchemer.openapi30
  # default: JSONSchemer.draft202012
  meta_schema: 'https://json-schema.org/draft/2020-12/schema',

  # validate `format` (https://json-schema.org/draft/2020-12/json-schema-validation.html#section-7)
  # true/false
  # default: true
  format: true,

  # custom formats
  formats: {
    'int32' => proc do |instance, _format|
      instance.is_a?(Integer) && instance.bit_length <= 32
    end,
    # disable specific format
    'email' => false
  },

  # custom content encodings
  # only `base64` is available by default
  content_encodings: {
    # return [success, annotation] tuple
    'urlsafe_base64' => proc do |instance|
      [true, Base64.urlsafe_decode64(instance)]
    rescue
      [false, nil]
    end
  },

  # custom content media types
  # only `application/json` is available by default
  content_media_types: {
    # return [success, annotation] tuple
    'text/csv' => proc do |instance|
      [true, CSV.parse(instance)]
    rescue
      [false, nil]
    end
  },

  # insert default property values during validation
  # string keys by default (use `:symbol` to insert symbol keys)
  # true/false/:symbol
  # default: false
  insert_property_defaults: true,

  # modify properties during validation. You can pass one Proc or a list of Procs to modify data.
  # Proc/[Proc]
  # default: nil
  before_property_validation: proc do |data, property, property_schema, _parent|
    data[property] ||= 42
  end,

  # modify properties after validation. You can pass one Proc or a list of Procs to modify data.
  # Proc/[Proc]
  # default: nil
  after_property_validation: proc do |data, property, property_schema, _parent|
    data[property] = Date.iso8601(data[property]) if property_schema.is_a?(Hash) && property_schema['format'] == 'date'
  end,

  # resolve external references
  # 'net/http'/proc/lambda/respond_to?(:call)
  # 'net/http': proc { |uri| JSON.parse(Net::HTTP.get(uri)) }
  # default: proc { |uri| raise UnknownRef, uri.to_s }
  ref_resolver: 'net/http',

  # use different method to match regexes
  # 'ruby'/'ecma'/proc/lambda/respond_to?(:call)
  # 'ruby': proc { |pattern| Regexp.new(pattern) }
  # default: 'ruby'
  regexp_resolver: proc do |pattern|
    RE2::Regexp.new(pattern)
  end,

  # output formatting (https://json-schema.org/draft/2020-12/json-schema-core.html#section-12)
  # 'classic'/'flag'/'basic'/'detailed'/'verbose'
  # default: 'classic'
  output_format: 'basic',

  # validate `readOnly`/`writeOnly` keywords (https://spec.openapis.org/oas/v3.0.3#fixed-fields-19)
  # 'read'/'write'/nil
  # default: nil
  access_mode: 'read'
)
```

## Global Configuration

Configuration options can be set globally by modifying `JSONSchemer.configuration`. Global options are applied to any new schemas at creation time (global configuration changes are not reflected in existing schemas). They can be overridden with the regular keyword arguments described [above](#options).

```ruby
# configuration block
JSONSchemer.configure do |config|
  config.regexp_resolver = 'ecma'
end

# configuration accessors
JSONSchemer.configuration.insert_property_defaults = true
```

## Custom Error Messages

Error messages can be customized using the `x-error` keyword and/or [I18n](https://github.com/ruby-i18n/i18n) translations. `x-error` takes precedence if both are defined.

### `x-error` Keyword

```ruby
# override all errors for a schema
schemer = JSONSchemer.schema({
  'type' => 'string',
  'x-error' => 'custom error for schema and all keywords'
})

schemer.validate(1).first
# => {"data"=>1,
#     "data_pointer"=>"",
#     "schema"=>{"type"=>"string", "x-error"=>"custom error for schema and all keywords"},
#     "schema_pointer"=>"",
#     "root_schema"=>{"type"=>"string", "x-error"=>"custom error for schema and all keywords"},
#     "type"=>"string",
#     "error"=>"custom error for schema and all keywords",
#     "x-error"=>true}

schemer.validate(1, :output_format => 'basic')
# => {"valid"=>false,
#     "keywordLocation"=>"",
#     "absoluteKeywordLocation"=>"json-schemer://schema#",
#     "instanceLocation"=>"",
#     "error"=>"custom error for schema and all keywords",
#     "x-error"=>true,
#     "errors"=>#<Enumerator: ...>}

# keyword-specific errors
schemer = JSONSchemer.schema({
  'type' => 'string',
  'minLength' => 10,
  'x-error' => {
    'type' => 'custom error for `type` keyword',
    # special `^` keyword for schema-level error
    '^' => 'custom error for schema',
    # same behavior as when `x-error` is a string
    '*' => 'fallback error for schema and all keywords'
  }
})

schemer.validate(1).map { _1.fetch('error') }
# => ["custom error for `type` keyword"]

schemer.validate('1').map { _1.fetch('error') }
# => ["custom error for schema and all keywords"]

schemer.validate(1, :output_format => 'basic').fetch('error')
# => "custom error for schema"

# variable interpolation (instance/instanceLocation/formattedInstanceLocation/keywordValue/keywordLocation/absoluteKeywordLocation/details)
schemer = JSONSchemer.schema({
  '$id' => 'https://example.com/schema',
  'properties' => {
    'abc' => {
      'type' => 'object',
      'required' => ['xyz'],
      'x-error' => <<~ERROR
        instance: %{instance}
        instance location: %{instanceLocation}
        formatted instance location: %{formattedInstanceLocation}
        keyword value: %{keywordValue}
        keyword location: %{keywordLocation}
        absolute keyword location: %{absoluteKeywordLocation}
        details: %{details}
        details__missing_keys: %{details__missing_keys}
      ERROR
    }
  }
})

puts schemer.validate({ 'abc' => {} }).first.fetch('error')
# instance: {}
# instance location: /abc
# formatted instance location: `/abc`
# keyword value: ["xyz"]
# keyword location: /properties/abc/required
# absolute keyword location: https://example.com/schema#/properties/abc/required
# details: {"missing_keys" => ["xyz"]}
# details__missing_keys: ["xyz"]
```

### I18n

When the [I18n gem](https://github.com/ruby-i18n/i18n) is loaded, custom error messages are looked up under the `json_schemer` key. It may be necessary to restart your application after adding the root key because the existence check is cached for performance reasons.

Translation keys are looked up in this order:

1. `$LOCALE.json_schemer.errors.$ABSOLUTE_KEYWORD_LOCATION`
2. `$LOCALE.json_schemer.errors.$SCHEMA_ID.$KEYWORD_LOCATION`
3. `$LOCALE.json_schemer.errors.$KEYWORD_LOCATION`
4. `$LOCALE.json_schemer.errors.$SCHEMA_ID.$KEYWORD`
5. `$LOCALE.json_schemer.errors.$SCHEMA_ID.*`
6. `$LOCALE.json_schemer.errors.$META_SCHEMA_ID.$KEYWORD`
7. `$LOCALE.json_schemer.errors.$META_SCHEMA_ID.*`
8. `$LOCALE.json_schemer.errors.$KEYWORD`
9. `$LOCALE.json_schemer.errors.*`

Example translations file:

```yaml
en:
  json_schemer:
    errors:
      # variable interpolation (instance/instanceLocation/formattedInstanceLocation/keywordValue/keywordLocation/absoluteKeywordLocation/details)
      'https://example.com/schema#/properties/abc/required': |
        custom error for absolute keyword location
        instance: %{instance}
        instance location: %{instanceLocation}
        formatted instance location: %{formattedInstanceLocation}
        keyword value: %{keywordValue}
        keyword location: %{keywordLocation}
        absolute keyword location: %{absoluteKeywordLocation}
        details: %{details}
        details__missing_keys: %{details__missing_keys}
      'https://example.com/schema':
        '#/properties/abc/required': custom error for keyword location, nested under schema $id
        'required': custom error for `required` keyword, nested under schema $id
        '^': custom error for schema, nested under schema $id
        '*': fallback error for schema and all keywords, nested under schema $id
      '#/properties/abc/required': custom error for keyword location
      'http://json-schema.org/draft-07/schema#':
        'required': custom error for `required` keyword, nested under meta-schema $id ($schema)
        '^': custom error for schema, nested under meta-schema $id
        '*': fallback error for schema and all keywords, nested under meta-schema $id ($schema)
      'required': custom error for `required` keyword
      '^': custom error for schema
      '*': fallback error for schema and all keywords
```

And output:

```ruby
require 'i18n'
I18n.locale = :en                                         # $LOCALE=en

schemer = JSONSchemer.schema({
  '$id' => 'https://example.com/schema',                  # $SCHEMA_ID=https://example.com/schema
  '$schema' => 'http://json-schema.org/draft-07/schema#', # $META_SCHEMA_ID=http://json-schema.org/draft-07/schema#
  'properties' => {
    'abc' => {
      'required' => ['xyz']                               # $KEYWORD=required
    }                                                     # $KEYWORD_LOCATION=#/properties/abc/required
  }                                                       # $ABSOLUTE_KEYWORD_LOCATION=https://example.com/schema#/properties/abc/required
})

schemer.validate({ 'abc' => {} }).first
# => {"data" => {},
#     "data_pointer" => "/abc",
#     "schema" => {"required" => ["xyz"]},
#     "schema_pointer" => "/properties/abc",
#     "root_schema" => {"$id" => "https://example.com/schema", "$schema" => "http://json-schema.org/draft-07/schema#", "properties" => {"abc" => {"required" => ["xyz"]}}},
#     "type" => "required",
#     "error" =>
#      "custom error for absolute keyword location\ninstance: {}\ninstance location: /abc\nformatted instance location: `/abc`\nkeyword value: [\"xyz\"]\nkeyword location: /properties/abc/required\nabsolute keyword location: https://example.com/schema#/properties/abc/required\ndetails: {\"missing_keys\" => [\"xyz\"]}\ndetails__missing_keys: [\"xyz\"]\n",
#     "i18n" => true,
#     "details" => {"missing_keys" => ["xyz"]}}

puts schemer.validate({ 'abc' => {} }).first.fetch('error')
# custom error for absolute keyword location
# instance: {}
# instance location: /abc
# formatted instance location: `/abc`
# keyword value: ["xyz"]
# keyword location: /properties/abc/required
# absolute keyword location: https://example.com/schema#/properties/abc/required
# details: {"missing_keys" => ["xyz"]}
# details__missing_keys: ["xyz"]
```

In the example above, custom error messsages are looked up using the following keys (in order until one is found):

1. `en.json_schemer.errors.'https://example.com/schema#/properties/abc/required'`
2. `en.json_schemer.errors.'https://example.com/schema'.'#/properties/abc/required'`
3. `en.json_schemer.errors.'#/properties/abc/required'`
4. `en.json_schemer.errors.'https://example.com/schema'.required`
5. `en.json_schemer.errors.'https://example.com/schema'.*`
6. `en.json_schemer.errors.'http://json-schema.org/draft-07/schema#'.required`
7. `en.json_schemer.errors.'http://json-schema.org/draft-07/schema#'.*`
8. `en.json_schemer.errors.required`
9. `en.json_schemer.errors.*`

## OpenAPI

```ruby
document = JSONSchemer.openapi({
  'openapi' => '3.1.0',
  'info' => {
    'title' => 'example'
  },
  'components' => {
    'schemas' => {
      'example' => {
        'type' => 'integer'
      }
    }
  }
})

# document validation using meta schema

document.valid?
# => false

document.validate.to_a
# => [{"data"=>{"title"=>"example"},
#      "data_pointer"=>"/info",
#      "schema"=>{...info schema},
#      "schema_pointer"=>"/$defs/info",
#      "root_schema"=>{...meta schema},
#      "type"=>"required",
#      "details"=>{"missing_keys"=>["version"]}},
#     ...]

# data validation using schema by name (in `components/schemas`)

document.schema('example').valid?(1)
# => true

document.schema('example').valid?('one')
# => false

# data validation using schema by ref

document.ref('#/components/schemas/example').valid?(1)
# => true

document.ref('#/components/schemas/example').valid?('one')
# => false
```

## CLI

The `json_schemer` executable takes a JSON schema file as the first argument followed by one or more JSON data files to validate. If there are any validation errors, it outputs them and returns an error code.

Validation errors are output as single-line JSON objects. The `--errors` option can be used to limit the number of errors returned or prevent output entirely (and fail fast).

The schema or data can also be read from stdin using `-`.

```
% json_schemer --help
Usage:
  json_schemer [options] <schema> <data>...
  json_schemer [options] <schema> -
  json_schemer [options] - <data>...
  json_schemer -h | --help
  json_schemer --version

Options:
  -e, --errors MAX                 Maximum number of errors to output
                                   Use "0" to validate with no output
  -h, --help                       Show help
  -v, --version                    Show version
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Build Status

![CI](https://github.com/davishmcclurg/json_schemer/actions/workflows/ci.yml/badge.svg)
![JSON Schema Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fbowtie.report%2Fbadges%2Fruby-json_schemer%2Fsupported_versions.json)<br>
![Draft 2020-12](https://img.shields.io/endpoint?url=https%3A%2F%2Fbowtie.report%2Fbadges%2Fruby-json_schemer%2Fcompliance%2Fdraft2020-12.json)
![Draft 2019-09](https://img.shields.io/endpoint?url=https%3A%2F%2Fbowtie.report%2Fbadges%2Fruby-json_schemer%2Fcompliance%2Fdraft2019-09.json)
![Draft 7](https://img.shields.io/endpoint?url=https%3A%2F%2Fbowtie.report%2Fbadges%2Fruby-json_schemer%2Fcompliance%2Fdraft7.json)
![Draft 6](https://img.shields.io/endpoint?url=https%3A%2F%2Fbowtie.report%2Fbadges%2Fruby-json_schemer%2Fcompliance%2Fdraft6.json)
![Draft 4](https://img.shields.io/endpoint?url=https%3A%2F%2Fbowtie.report%2Fbadges%2Fruby-json_schemer%2Fcompliance%2Fdraft4.json)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davishmcclurg/json_schemer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
