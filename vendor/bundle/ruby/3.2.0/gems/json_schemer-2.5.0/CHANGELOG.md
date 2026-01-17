# Changelog

## [2.5.0] - 2025-12-08

### Bug Fixes

- Apply `discriminator` before unevaluated keywords: https://github.com/davishmcclurg/json_schemer/pull/220
- Disallow trailing dots in hostname formats: https://github.com/davishmcclurg/json_schemer/pull/226
- Limit overall size in hostname formats: https://github.com/davishmcclurg/json_schemer/pull/226
- Support extended set of separators in hostname formats: https://github.com/davishmcclurg/json_schemer/pull/226

### Features

- More interpolation variables for custom error messages: https://github.com/davishmcclurg/json_schemer/pull/211

[2.5.0]: https://github.com/davishmcclurg/json_schemer/releases/tag/v2.5.0

## [2.4.0] - 2025-02-01

### Bug Fixes

- Store schema resource file URIs as strings to prevent conflicts: https://github.com/davishmcclurg/json_schemer/pull/189
- Require OpenAPI `discriminator` instances to be objects: https://github.com/davishmcclurg/json_schemer/pull/206
- Pass configuration options to subschemas: https://github.com/davishmcclurg/json_schemer/pull/208
- Check applicable instance types in OpenAPI `format` extensions: https://github.com/davishmcclurg/json_schemer/pull/209
- Use correct max values for OpenAPI `int32`/`int64` formats: https://github.com/davishmcclurg/json_schemer/commit/386c2a6fe089350c61775716643ef0600898060e

[2.4.0]: https://github.com/davishmcclurg/json_schemer/releases/tag/v2.4.0

## [2.3.0] - 2024-05-30

### Ruby Versions

- Ruby 2.5 and 2.6 are no longer supported.

### Bug Fixes

- Remove `base64` runtime dependency: https://github.com/davishmcclurg/json_schemer/pull/182
- Relax `uuid` format validation: https://github.com/davishmcclurg/json_schemer/pull/183

[2.3.0]: https://github.com/davishmcclurg/json_schemer/releases/tag/v2.3.0

## [2.2.0] - 2024-03-02

### Bug Fixes

- Support symbol keys when accessing original instance: https://github.com/davishmcclurg/json_schemer/commit/d52c130e9967919c6cf1c9dbc3f0babfb8b01cf8
- Support custom keywords in nested schemas: https://github.com/davishmcclurg/json_schemer/commit/93c85a5006981347c7e9a4c11b73c6bdb65d8ba2
- Stringify instance location for custom keywords: https://github.com/davishmcclurg/json_schemer/commit/513c99130b9e7986b09881e7efd3fb7143744754
- Reduce unhelpful error output in `unevaluated` keywords: https://github.com/davishmcclurg/json_schemer/pull/164
- Handle parse errors during schema validation: https://github.com/davishmcclurg/json_schemer/pull/171
- Follow refs when finding default property values: https://github.com/davishmcclurg/json_schemer/pull/175

### Features

- Global configuration with `Configuration` object: https://github.com/davishmcclurg/json_schemer/pull/170
- Symbol key property defaults with `insert_property_defaults: :symbol`: https://github.com/davishmcclurg/json_schemer/commit/a72473dc84199107ddedc8998950e5b82273232a
- Consistent schema type support for schema validation methods: https://github.com/davishmcclurg/json_schemer/commit/bbcd0cea20cbaa61cf2bdae5f53840861cae54b8
- Validation option support for schema validation methods: https://github.com/davishmcclurg/json_schemer/commit/2eeef77de522f127619b7d0faa51e0d7e40977ad

[2.2.0]: https://github.com/davishmcclurg/json_schemer/releases/tag/v2.2.0

## [2.1.1] - 2023-11-28

### Bug Fixes

- Fix refs to/through keyword objects: https://github.com/davishmcclurg/json_schemer/pull/160
- Temporary fix for incorrect `uri-reference` format in OpenAPI 3.x: https://github.com/davishmcclurg/json_schemer/pull/161

[2.1.1]: https://github.com/davishmcclurg/json_schemer/releases/tag/v2.1.1

## [2.1.0] - 2023-11-17

### Bug Fixes

- Limit anyOf/oneOf discriminator to listed refs: https://github.com/davishmcclurg/json_schemer/pull/145
- Require discriminator `propertyName` property: https://github.com/davishmcclurg/json_schemer/pull/145
- Support `Schema#ref` in subschemas: https://github.com/davishmcclurg/json_schemer/pull/145
- Resolve JSON pointer refs using correct base URI: https://github.com/davishmcclurg/json_schemer/pull/147
- `date` format in OpenAPI 3.0: https://github.com/davishmcclurg/json_schemer/commit/69fe7a815ecf0cfb1c40ac402bf46a789c05e972

### Features

- Custom error messages with `x-error` keyword and I18n: https://github.com/davishmcclurg/json_schemer/pull/149
- Custom content encodings and media types: https://github.com/davishmcclurg/json_schemer/pull/148

[2.1.0]: https://github.com/davishmcclurg/json_schemer/releases/tag/v2.1.0

## [2.0.0] - 2023-08-20

For 2.0.0, much of the codebase was rewritten to simplify support for the two new JSON Schema draft versions (2019-09 and 2020-12). The major change is moving each keyword into its own class and organizing them into vocabularies. [Output formats](https://json-schema.org/draft/2020-12/json-schema-core.html#section-12) and [annotations](https://json-schema.org/draft/2020-12/json-schema-core.html#section-7.7) from the new drafts are also supported. The known breaking changes are listed below, but there may be others that haven't been identified.

### Breaking Changes

- The default meta schema is now Draft 2020-12. Other meta schemas can be specified using `meta_schema`.
- Schemas use `json-schemer://schema` as the default base URI. Relative `$id` and `$ref` values are joined to the default base URI and are always absolute. For example, the schema `{ '$id' => 'foo', '$ref' => 'bar' }` uses `json-schemer://schema/foo` as the base URI and passes `json-schemer://schema/bar` to the ref resolver. For relative refs, `URI#path` can be used in the ref resolver to access the relative portion, ie: `URI('json-schemer://schema/bar').path => "/bar"`.
- Property validation hooks (`before_property_validation` and `after_property_validation`) run immediately before and after `properties` validation. Previously, `before_property_validation` ran before all "object" validations (`dependencies`, `patternProperties`, `additionalProperties`, etc) and `after_property_validation` was called after them.
- `insert_property_defaults` now inserts defaults in conditional subschemas when possible (if there's only one default or if there's only one unique default from a valid subtree).
- Error output
  - Special characters in `schema_pointer` are no longer percent encoded (eg, `definitions/foo\"bar` instead of `/definitions/foo%22bar`)
  - Keyword validation order changed so errors may be returned in a different order (eg, `items` errors before `contains`).
  - Array `dependencies` return `"type": "dependencies"` errors instead of `"required"` and point to the schema that contains the `dependencies` keyword.
  - `not` errors point to the schema that contains the `not` keyword (instead of the schema defined by the `not` keyword).
  - Custom keyword errors are now always wrapped in regular error hashes. Returned strings are used to set `type`:
      ```
      >> JSONSchemer.schema({ 'x' => 'y' }, :keywords => { 'x' => proc { false } }).validate({}).to_a
      => [{"data"=>{}, "data_pointer"=>"", "schema"=>{"x"=>"y"}, "schema_pointer"=>"", "root_schema"=>{"x"=>"y"}, "type"=>"x"}]
      >> JSONSchemer.schema({ 'x' => 'y' }, :keywords => { 'x' => proc { 'wrong!' } }).validate({}).to_a
      => [{"data"=>{}, "data_pointer"=>"", "schema"=>{"x"=>"y"}, "schema_pointer"=>"", "root_schema"=>{"x"=>"y"}, "type"=>"wrong!"}]
      ```

[2.0.0]: https://github.com/davishmcclurg/json_schemer/releases/tag/v2.0.0

## [1.0.0] - 2023-05-26

### Breaking Changes

- Ruby 2.4 is no longer supported.
- The default `regexp_resolver` is now `ruby`, which passes patterns directly to `Regexp`. The previous default, `ecma`, rewrites patterns to behave more like Javascript (ECMA-262) regular expressions:
  - Beginning of string: `^` -> `\A`
  - End of string: `$` -> `\z`
  - Space: `\s` -> `[\t\r\n\f\v\uFEFF\u2029\p{Zs}]`
  - Non-space: `\S` -> `[^\t\r\n\f\v\uFEFF\u2029\p{Zs}]`
- Invalid ECMA-262 regular expressions raise `JSONSchemer::InvalidEcmaRegexp` when `regexp_resolver` is set to `ecma`.
- Embedded subschemas (ie, subschemas referenced by `$id`) can only be found under "known" keywords (eg, `definitions`). Previously, the entire schema object was scanned for `$id`.
- Empty fragments are now removed from `$ref` URIs before calling `ref_resolver`.
- Refs that are fragment-only JSON pointers with special characters must use the proper encoding (eg, `"$ref": "#/definitions/some-%7Bid%7D"`).

[1.0.0]: https://github.com/davishmcclurg/json_schemer/releases/tag/v1.0.0
