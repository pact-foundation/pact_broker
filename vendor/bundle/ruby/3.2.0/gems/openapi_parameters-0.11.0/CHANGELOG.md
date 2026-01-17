## [Unreleased]

## [0.11.0] - 2025-11-30

- Changed:  Passing a plain query string like `filter=ada` to a`deepObject` parameter instead of using the brackets syntax `filter[name]=ada` no longer results in an empty object, but in the plain string value (like `{ filter: 'ada'} `), which will make request validation fail.

## [0.10.0] - 2025-11-23

- remove `OpenapiParameters::Parameter#definition` to clean up interface
- Add `OpenapiParameters::Query#unknown_values` to find unknown query parameters

## [0.9.0] - 2025-11-07

- Add support for unpacking query parameters that use deepObject and oneOf,andOf,anyOf,if-them-else

## [0.8.0] - 2025-09-17

- No longer parse more than one level of nested objects when parsing `deepObject` parameters. This is actually in line with what `deepObject` supports.

## [0.7.0] - 2025-09-12

- Correctly handle `style:deepObject` with `explode: true` and parse into array
  ```ruby
  OpenapiParameters::Query.new(
      [parameter],
      explode: true
  ).unpack('ids=1&ids=2')
  # => { 'ids' => ['1', '2'] }
  ```

## [0.6.1] - 2025-06-23

- Fix converting items of array parameters

## [0.6.0] - 2025-06-23

- Array parameters without a value ("?ids=" or "?ids") return an empty array instead of nil or an empty string.
  This makes parsing more consistent, because it should not matter if "=" is added or not.

## [0.5.1] - 2025-06-17

- Raise `Rack::Utils::InvalidParameterError` when query paramter has invalid "%"-encoding

## [0.5.0] - 2025-04-01

- Add option to remove "[]" from unpacked query openapi_parameters
  ```ruby
  OpenapiParameters::Query.new(
    [parameter],
    rack_array_compat: true
  ).unpack('ids[]=2')
  # => { 'ids' => ['2'] }
  ```

## [0.4.0] - 2024-12-17

- Add Parameter#convert(value)
- Slight performance optimization

## [0.3.4] - 2024-06-14

- Fix handling invalid object query parameters (String vs Hash)

## [0.3.3] - 2023-04-13

- Remove zeitwerk. It's awesome, but not needed here

## [0.3.2] - 2023-11-14

- Assume that schemas with `properties` or `style: deepObject` describe Objects and therefore convert it's values.

## [0.3.1] - 2023-11-09

- Make it work with Zeitwerk's `eager_load`

## [0.3.0] - 2023-10-27

- Query parameters: Don't attempt to convert arras within deepObject objects. Behaviour is not defined in OpenApi 3.1.

## [0.2.2] - 2023-06-01

- Remove superflous validation of "in" property
- Remove superfluous check for unsupported $ref inside parameter schema

## [0.2.1] - 2023-03-31

- Fix links in gemspec

## [0.2.0] - 2023-03-30

- Breaking: Path parameters are unpacked from a hash, which is usually available from the used Rack web framework. This is much simpler and more performant.

## [0.1.0] - 2023-03-25

- Initial release
