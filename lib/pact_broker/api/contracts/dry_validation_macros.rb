require "pact_broker/api/contracts/dry_validation_methods"

Dry::Validation.register_macro(:not_multiple_lines) do
  PactBroker::Api::Contracts::DryValidationMethods.validate_not_multiple_lines(value, key)
end

Dry::Validation.register_macro(:no_spaces_if_present) do
  PactBroker::Api::Contracts::DryValidationMethods.validate_no_spaces_if_present(value, key)
end

Dry::Validation.register_macro(:not_blank_if_present) do
  PactBroker::Api::Contracts::DryValidationMethods.validate_not_blank_if_present(value, key)
end

Dry::Validation.register_macro(:array_values_not_blank_if_any) do
  value&.each_with_index do | item, index |
    PactBroker::Api::Contracts::DryValidationMethods.validate_not_blank_if_present(item, key(path.keys + [index]))
  end
end

Dry::Validation.register_macro(:valid_url_if_present) do
  PactBroker::Api::Contracts::DryValidationMethods.validate_valid_url(value, key)
end

Dry::Validation.register_macro(:valid_version_number) do
  PactBroker::Api::Contracts::DryValidationMethods.validate_version_number(value, key)
end

Dry::Validation.register_macro(:pacticipant_with_name_exists) do
  PactBroker::Api::Contracts::DryValidationMethods.validate_pacticipant_with_name_exists(value, key)
end

# Validate each object in an array with the specified contract,
# and merge the errors into the appropriate path in the parent
# validation results.
# eg.
#    rule(:myChildArray).validate(validate_each_with_contract: MyChildContract)
#
# If the child contract defines a option called `parent` then it can access the parent
# hash for validation rules that need to work across the levels.
# eg. ConsumerVersionSelectorContract for the matchingBranch rule
Dry::Validation.register_macro(:validate_each_with_contract) do |macro:|
  value&.each_with_index do | item, index |
    child_contract_class = macro.args[0]
    messages = child_contract_class.new(parent: values).call(item).errors(full: true).to_hash.values.flatten
    messages.each do | message |
      key(path.keys + [index]).failure(message)
    end
  end
end
