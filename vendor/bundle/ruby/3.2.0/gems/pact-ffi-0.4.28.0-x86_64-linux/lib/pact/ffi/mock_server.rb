# require 'pact-ffi/version'
require 'ffi'
require 'pact/detect_os'

module PactFfi
  module MockServer
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

    attach_function :create, :pactffi_create_mock_server, %i[string string bool], :int32
    attach_function :get_tls_cert, :pactffi_get_tls_ca_certificate, %i[], :string
    attach_function :create_for_pact, :pactffi_create_mock_server_for_pact, %i[uint16 string bool], :int32
    attach_function :create_for_transport, :pactffi_create_mock_server_for_transport, %i[uint16 string uint16 string string], :int32
    attach_function :matched, :pactffi_mock_server_matched, %i[int32], :bool
    attach_function :mismatches, :pactffi_mock_server_mismatches, %i[int32], :string
    attach_function :cleanup, :pactffi_cleanup_mock_server, %i[int32], :bool
    attach_function :write_pact_file, :pactffi_write_pact_file, %i[int32 string bool], :int32
    attach_function :logs, :pactffi_mock_server_logs, %i[int32], :string
  end
end
