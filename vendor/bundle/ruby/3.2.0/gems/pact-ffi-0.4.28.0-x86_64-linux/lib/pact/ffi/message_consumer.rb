# require 'pact-ffi/version'
require 'ffi'
require 'pact/detect_os'

module PactFfi
  module MessageConsumer
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

    attach_function :contents_get_contents_str, :pactffi_message_contents_get_contents_str, %i[pointer], :string
    attach_function :contents_delete, :pactffi_message_contents_delete, %i[pointer], :void
    attach_function :contents_set_contents_str, :pactffi_message_contents_set_contents_str, %i[pointer string string], :void
    attach_function :contents_get_contents_length, :pactffi_message_contents_get_contents_length, %i[pointer], :size_t
    attach_function :contents_get_contents_bin, :pactffi_message_contents_get_contents_bin, %i[pointer], :pointer
    attach_function :contents_set_contents_bin, :pactffi_message_contents_set_contents_bin, %i[pointer pointer size_t string], :void
    attach_function :contents_get_metadata_iter, :pactffi_message_contents_get_metadata_iter, %i[pointer], :pointer
    attach_function :contents_get_matching_rule_iter, :pactffi_message_contents_get_matching_rule_iter, %i[pointer int32], :pointer
    attach_function :message_contents_get_generators_iter, :pactffi_message_contents_get_generators_iter, %i[pointer int32], :pointer
    attach_function :pact_interaction_as_message, :pactffi_pact_interaction_as_message, %i[pointer], :pointer
    attach_function :new, :pactffi_message_new, %i[], :pointer
    attach_function :new_from_json, :pactffi_message_new_from_json, %i[uint32_type string int32], :pointer
    attach_function :new_from_body, :pactffi_message_new_from_body, %i[string string], :pointer
    attach_function :delete, :pactffi_message_delete, %i[pointer], :void
    attach_function :get_contents, :pactffi_message_get_contents, %i[pointer], :string
    attach_function :set_contents, :pactffi_message_set_contents, %i[pointer string string], :void
    attach_function :get_contents_length, :pactffi_message_get_contents_length, %i[pointer], :size_t
    attach_function :get_contents_bin, :pactffi_message_get_contents_bin, %i[pointer], :pointer
    attach_function :set_contents_bin, :pactffi_message_set_contents_bin, %i[pointer pointer size_t string], :void
    attach_function :get_description, :pactffi_message_get_description, %i[pointer], :string
    attach_function :set_description, :pactffi_message_set_description, %i[pointer string], :int32
    attach_function :get_provider_state, :pactffi_message_get_provider_state, %i[pointer uint32_type], :pointer
    attach_function :get_provider_state_iter, :pactffi_message_get_provider_state_iter, %i[pointer], :pointer
    attach_function :find_metadata, :pactffi_message_find_metadata, %i[pointer string], :string
    attach_function :insert_metadata, :pactffi_message_insert_metadata, %i[pointer string string], :int32
    attach_function :metadata_iter_next, :pactffi_message_metadata_iter_next, %i[pointer], :pointer
    attach_function :get_metadata_iter, :pactffi_message_get_metadata_iter, %i[pointer], :pointer
    attach_function :metadata_iter_delete, :pactffi_message_metadata_iter_delete, %i[pointer], :void
    attach_function :metadata_pair_delete, :pactffi_message_metadata_pair_delete, %i[pointer], :void
    attach_function :new_from_json, :pactffi_message_pact_new_from_json, %i[string string], :pointer
    attach_function :delete, :pactffi_message_pact_delete, %i[pointer], :void
    attach_function :get_consumer, :pactffi_message_pact_get_consumer, %i[pointer], :pointer
    attach_function :get_provider, :pactffi_message_pact_get_provider, %i[pointer], :pointer
    attach_function :get_message_iter, :pactffi_message_pact_get_message_iter, %i[pointer], :pointer
    attach_function :message_iter_next, :pactffi_message_pact_message_iter_next, %i[pointer], :pointer
    attach_function :message_iter_delete, :pactffi_message_pact_message_iter_delete, %i[pointer], :void
    attach_function :find_metadata, :pactffi_message_pact_find_metadata, %i[pointer string string], :string
    attach_function :get_metadata_iter, :pactffi_message_pact_get_metadata_iter, %i[pointer], :pointer
    attach_function :metadata_iter_next, :pactffi_message_pact_metadata_iter_next, %i[pointer], :pointer
    attach_function :metadata_iter_delete, :pactffi_message_pact_metadata_iter_delete, %i[pointer], :void
    attach_function :metadata_triple_delete, :pactffi_message_pact_metadata_triple_delete, %i[pointer], :void
    attach_function :new_message_interaction, :pactffi_new_message_interaction, %i[uint16 string], :uint32_type
    attach_function :new_message_pact, :pactffi_new_message_pact, %i[string string], :uint16
    attach_function :new_message, :pactffi_new_message, %i[uint16 string], :uint32_type
    attach_function :expects_to_receive, :pactffi_message_expects_to_receive, %i[uint32_type string], :void
    attach_function :given, :pactffi_message_given, %i[uint32_type string], :void
    attach_function :given_with_param, :pactffi_message_given_with_param, %i[uint32_type string string string], :void
    attach_function :with_contents, :pactffi_message_with_contents, %i[uint32_type string pointer size_t], :void
    attach_function :with_metadata, :pactffi_message_with_metadata, %i[uint32_type string string], :void
    attach_function :reify, :pactffi_message_reify, %i[uint32_type], :string
    attach_function :write_message_pact_file, :pactffi_write_message_pact_file, %i[uint16 string bool], :int32
    attach_function :with_message_pact_metadata, :pactffi_with_message_pact_metadata, %i[uint16 string string string], :void
    attach_function :free_handle, :pactffi_free_message_pact_handle, %i[uint16], :uint32_type
    attach_function :pact_handle_get_message_iter, :pactffi_pact_handle_get_message_iter, %i[uint16], :pointer
    attach_function :with_metadata_v2, :pactffi_message_with_metadata_v2, %i[uint32_type string string], :void
  end
end
