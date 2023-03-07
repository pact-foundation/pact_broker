# Using dry-validation

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

* I cannot find any native support for Contract composition (there's schema composition, but I can't find Contract composition). I have written a macro called `validate_each_with_contract` in lib/pact_broker/api/contracts/dry_validation_macros.rb which allows an array of child items to be validated by a contract that is defined in a separate file, merging the results into the parent's results. There's an example in lib/pact_broker/api/contracts/pacts_for_verification_json_query_schema.rb
* The format that dry-validation returns the error messages for arrays didn't work with the original error format, so the returned hash is munged into the expected format in lib/pact_broker/api/contracts/dry_validation_workarounds.rb
