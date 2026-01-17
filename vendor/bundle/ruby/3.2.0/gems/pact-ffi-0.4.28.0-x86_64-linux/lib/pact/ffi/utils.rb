# require 'pact-ffi/version'
require 'ffi'
require 'pact/detect_os'

module PactFfi
  module Utils
    extend FFI::Library
    ffi_lib DetectOS.get_bin_path

    # DetectOS.windows? || DetectOS.linux_arm? ? (typedef :uint32, :uint32_type) : (typedef :uint32_t, :uint32_type)
    (typedef :uint32, :uint32_type) 
    FfiSpecificationVersion = Hash[
      'SPECIFICATION_VERSION_UNKNOWN' => 0,
      'SPECIFICATION_VERSION_V1' => 1,
      'SPECIFICATION_VERSION_V1_1' => 2,
      'SPECIFICATION_VERSION_V2' => 3,
      'SPECIFICATION_VERSION_V3' => 4,
      'SPECIFICATION_VERSION_V4' => 5,
    ]
    FfiWritePactResponse = Hash[
      'SUCCESS' => 0,
      'GENERAL_PANIC' => 1,
      'UNABLE_TO_WRITE_PACT_FILE' => 2,
      'MOCK_SERVER_NOT_FOUND' => 3,
    ]
    FfiWriteMessagePactResponse = Hash[
      'SUCCESS' => 0,
      'UNABLE_TO_WRITE_PACT_FILE' => 1,
      'MESSAGE_HANDLE_INVALID' => 2,
      'MOCK_SERVER_NOT_FOUND' => 3,
    ]
    FfiConfigurePluginResponse = Hash[
      'SUCCESS' => 0,
      'GENERAL_PANIC' => 1,
      'FAILED_TO_LOAD_PLUGIN' => 2,
      'PACT_HANDLE_INVALID' => 3,
    ]
    FfiPluginInteractionResponse = Hash[
      'SUCCESS' => 0,
      'A_GENERAL_PANIC_WAS_CAUGHT' => 1,
      'MOCK_SERVER_HAS_ALREADY_BEEN_STARTED' => 2,
      'INTERACTION_HANDLE_IS_INVALID' => 3,
      'CONTENT_TYPE_IS_NOT_VALID' => 4,
      'CONTENTS_JSON_IS_NOT_VALID_JSON' => 5,
      'PLUGIN_RETURNED_AN_ERROR' => 6,
    ]
    FfiInteractionPart = Hash[
      'INTERACTION_PART_REQUEST' => 0,
      'INTERACTION_PART_RESPONSE' => 1,
    ]
    # /*
    # -1	A null pointer was received
    # -2	The pact JSON could not be parsed
    # -3	The mock server could not be started
    # -4	The method panicked
    # -5	The address is not valid
    # -6	Could not create the TLS configuration with the self-signed certificate
    # */
    FfiPluginCreateMockServerErrors = Hash[
      'NULL_POINTER' => -1,
      'JSON_PARSE_ERROR' => -2,
      'MOCK_SERVER_START_FAIL' => -3,
      'CORE_PANIC' => -4,
      'ADDRESS_NOT_VALID' => -5,
      'TLS_CONFIG' => -6,
    ]

    FfiPluginFunctionResult = Hash[
      'RESULT_OK' => 0,
      'RESULT_FAILED' => 1,
    ]

    attach_function :add_text_comment, :pactffi_add_text_comment, %i[uint32_type string], :bool
    attach_function :set_comment, :pactffi_set_comment, %i[uint32_type string string], :bool
    attach_function :set_pending, :pactffi_set_pending, %i[uint32_type bool], :bool
    attach_function :set_key, :pactffi_set_key, %i[uint32_type string], :bool
    attach_function :match_message, :pactffi_match_message, %i[pointer pointer], :pointer
    attach_function :mismatches_get_iter, :pactffi_mismatches_get_iter, %i[pointer], :pointer
    attach_function :mismatches_delete, :pactffi_mismatches_delete, %i[pointer], :void
    attach_function :mismatches_iter_next, :pactffi_mismatches_iter_next, %i[pointer], :pointer
    attach_function :mismatches_iter_delete, :pactffi_mismatches_iter_delete, %i[pointer], :void
    attach_function :mismatch_to_json, :pactffi_mismatch_to_json, %i[pointer], :string
    attach_function :mismatch_type, :pactffi_mismatch_type, %i[pointer], :string
    attach_function :mismatch_summary, :pactffi_mismatch_summary, %i[pointer], :string
    attach_function :mismatch_description, :pactffi_mismatch_description, %i[pointer], :string
    attach_function :mismatch_ansi_description, :pactffi_mismatch_ansi_description, %i[pointer], :string
    attach_function :get_error_message, :pactffi_get_error_message, %i[string int32], :int32
    attach_function :parse_pact_json, :pactffi_parse_pact_json, %i[string], :pointer
    attach_function :pact_model_delete, :pactffi_pact_model_delete, %i[pointer], :void
    attach_function :pact_model_interaction_iterator, :pactffi_pact_model_interaction_iterator, %i[pointer], :pointer
    attach_function :pact_spec_version, :pactffi_pact_spec_version, %i[pointer], :int32
    attach_function :pact_interaction_delete, :pactffi_pact_interaction_delete, %i[pointer], :void
    attach_function :consumer_get_name, :pactffi_consumer_get_name, %i[pointer], :string
    attach_function :pact_get_consumer, :pactffi_pact_get_consumer, %i[pointer], :pointer
    attach_function :pact_consumer_delete, :pactffi_pact_consumer_delete, %i[pointer], :void
    attach_function :parse_matcher_definition, :pactffi_parse_matcher_definition, %i[string], :pointer
    attach_function :matcher_definition_error, :pactffi_matcher_definition_error, %i[pointer], :string
    attach_function :matcher_definition_value, :pactffi_matcher_definition_value, %i[pointer], :string
    attach_function :matcher_definition_delete, :pactffi_matcher_definition_delete, %i[pointer], :void
    attach_function :matcher_definition_generator, :pactffi_matcher_definition_generator, %i[pointer], :pointer
    attach_function :matcher_definition_value_type, :pactffi_matcher_definition_value_type, %i[pointer], :int32
    attach_function :matching_rule_iter_delete, :pactffi_matching_rule_iter_delete, %i[pointer], :void
    attach_function :matcher_definition_iter, :pactffi_matcher_definition_iter, %i[pointer], :pointer
    attach_function :matching_rule_iter_next, :pactffi_matching_rule_iter_next, %i[pointer], :pointer
    attach_function :matching_rule_id, :pactffi_matching_rule_id, %i[pointer], :uint16
    attach_function :matching_rule_value, :pactffi_matching_rule_value, %i[pointer], :string
    attach_function :matching_rule_pointer, :pactffi_matching_rule_pointer, %i[pointer], :pointer
    attach_function :matching_rule_reference_name, :pactffi_matching_rule_reference_name, %i[pointer], :string
    attach_function :validate_datetime, :pactffi_validate_datetime, %i[string string], :int32
    attach_function :generator_to_json, :pactffi_generator_to_json, %i[pointer], :string
    attach_function :generator_generate_string, :pactffi_generator_generate_string, %i[pointer string], :string
    attach_function :generator_generate_integer, :pactffi_generator_generate_integer, %i[pointer string], :uint16
    attach_function :generators_iter_delete, :pactffi_generators_iter_delete, %i[pointer], :void
    attach_function :generators_iter_next, :pactffi_generators_iter_next, %i[pointer], :pointer
    attach_function :generators_iter_pair_delete, :pactffi_generators_iter_pair_delete, %i[pointer], :void
    attach_function :matching_rule_to_json, :pactffi_matching_rule_to_json, %i[pointer], :string
    attach_function :matching_rules_iter_delete, :pactffi_matching_rules_iter_delete, %i[pointer], :void
    attach_function :matching_rules_iter_next, :pactffi_matching_rules_iter_next, %i[pointer], :pointer
    attach_function :matching_rules_iter_pair_delete, :pactffi_matching_rules_iter_pair_delete, %i[pointer], :void
    attach_function :provider_state_iter_next, :pactffi_provider_state_iter_next, %i[pointer], :pointer
    attach_function :provider_state_iter_delete, :pactffi_provider_state_iter_delete, %i[pointer], :void
    attach_function :provider_get_name, :pactffi_provider_get_name, %i[pointer], :string
    attach_function :pact_get_provider, :pactffi_pact_get_provider, %i[pointer], :pointer
    attach_function :pact_provider_delete, :pactffi_pact_provider_delete, %i[pointer], :void
    attach_function :provider_state_get_name, :pactffi_provider_state_get_name, %i[pointer], :string
    attach_function :provider_state_get_param_iter, :pactffi_provider_state_get_param_iter, %i[pointer], :pointer
    attach_function :provider_state_param_iter_next, :pactffi_provider_state_param_iter_next, %i[pointer], :pointer
    attach_function :provider_state_delete, :pactffi_provider_state_delete, %i[pointer], :void
    attach_function :provider_state_param_iter_delete, :pactffi_provider_state_param_iter_delete, %i[pointer], :void
    attach_function :provider_state_param_pair_delete, :pactffi_provider_state_param_pair_delete, %i[pointer], :void
    attach_function :string_delete, :pactffi_string_delete, %i[string], :void
    attach_function :generate_datetime_string, :pactffi_generate_datetime_string, %i[string], :pointer
    attach_function :check_regex, :pactffi_check_regex, %i[string string], :bool
    attach_function :generate_regex_value, :pactffi_generate_regex_value, %i[string], :pointer
    attach_function :free_string, :pactffi_free_string, %i[string], :void
    attach_function :new_pact, :pactffi_new_pact, %i[string string], :uint16
    attach_function :interaction_contents, :pactffi_interaction_contents, %i[uint32_type int32 string string],
                    :uint32_type
    attach_function :matches_string_value, :pactffi_matches_string_value, %i[pointer string string uint8], :string
    attach_function :matches_u64_value, :pactffi_matches_u64_value, %i[pointer ulong_long ulong_long uint8], :string
    attach_function :matches_i64_value, :pactffi_matches_i64_value, %i[pointer int64 int64 uint8], :string
    attach_function :matches_f64_value, :pactffi_matches_f64_value, %i[pointer double double uint8], :string
    attach_function :matches_bool_value, :pactffi_matches_bool_value, %i[pointer uint8 uint8 uint8], :string
    attach_function :matches_binary_value, :pactffi_matches_binary_value,
                    %i[pointer pointer ulong_long pointer ulong_long uint8], :string
    attach_function :matches_json_value, :pactffi_matches_json_value, %i[pointer string string uint8], :string
    attach_function :pact_handle_to_pointer, :pactffi_pact_handle_to_pointer, %i[uint16], :pointer
    attach_function :handle_get_pact_spec_version, :pactffi_handle_get_pact_spec_version, %i[uint16], :int32
    attach_function :with_metadata, :pactffi_with_metadata, %i[uint32_type string string int32], :bool
  end
end
