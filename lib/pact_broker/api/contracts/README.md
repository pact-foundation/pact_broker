# Request validation

Note: in this document, the word "contract" means a Dry::Validation::Contract, not a Pact consumer contract.

## History of the validation errors format

The original Pact Broker validation contracts returned a Hash in the format { "key[.key]" => ["error"] }.
When we upgraded the contracts to Dry::Validation v1.8, we added a `.call` method to the
PactBroker::Api::Contracts::BaseContract class that converted the Dry::Validation::MessageSet
into a Hash, in as close to the original format as possible.
We have since started supporting error responses in the problem+json format, so it makes more sense
to have the contracts return the Dry::Validation::Result, and then use different decorators
to render either the problem+json response or the old hash format.

To avoid having to update every single contract spec, the validation specs use the method `format_errors_the_old_way(dry_validation_result)`
from spec/support/api_contract_support.rb to convert the Dry::Validation::Result back into the old Hash format. New specs do not need to do this.

## Things you need to know about dry-validation

* It's better than it used to be.
* There are two parts to a Dry Validation contract.
  * Schemas: are for defining TYPES and presence of values. They come in 3 different flavours - json, string params, and vanilla https://dry-rb.org/gems/dry-validation/1.8/schemas/. We generally use the JSON one.
  * Rules: are for applying VALIDATION RULES. Don't try and put validation rules in the schema, or you'll end up wanting to punch something.
* The schema is applied first, and only if it passes are the rules evaluated for that particular parameter.
* The rules do NOT stop evaluating when one of them fails. Beth thinks this is less than ideal.
* Macros allow you to apply rules to fields in a declarative way. https://dry-rb.org/gems/dry-validation/1.8/macros/ We have some [here](lib/pact_broker/api/contracts/dry_validation_macros.rb)
* The docs are brief, but worth skimming through
  * https://dry-rb.org/gems/dry-validation/1.8/
  * https://dry-rb.org/gems/dry-schema/1.10/
* You can include modules and define methods inside the Contract classes.
* the "filled?" predicate in dry-schema will fail for "" but pass for " "

## dry-validation modifications for Pact Broker

* I cannot find any native support for Contract composition (there's schema composition, but I can't find Contract composition). The macros `validate_with_contract` and `validate_each_with_contract` in lib/pact_broker/api/contracts/dry_validation_macros.rb allow a child item or array of child items to be validated by a contract that is defined in a separate file, merging the results into the parent's results. There's an example in lib/pact_broker/api/contracts/pacts_for_verification_json_query_schema.rb
* The format that dry-validation returns the error messages for arrays didn't work with the original Pact Broker error format, so the errors are formatted in lib/pact_broker/api/contracts/dry_validation_errors_formatter.rb (one day, the errors should be returned directly to the resource, and the error decorator can either format them in problem json, or raw hash)

