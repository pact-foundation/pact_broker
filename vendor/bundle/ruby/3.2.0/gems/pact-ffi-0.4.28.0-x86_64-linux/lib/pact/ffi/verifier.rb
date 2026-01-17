# require 'pact/native_verifier/version'
# require 'pact/native_verifier/app'

# require 'pact-ffi/version'
require 'ffi'
require 'pact/detect_os'

module PactFfi
  module Verifier
    extend FFI::Library
    ffi_lib DetectOS.get_bin_path
    # DetectOS.windows? || DetectOS.linux_arm? ? (typedef :uint32, :uint32_type) : (typedef :uint32_t, :uint32_type)
    (typedef :uint32, :uint32_type) 

    # /*
    #  * | Error | Description |
    #  * |-------|-------------|
    #  * | 1 | The verification process failed, see output for errors |
    #  * | 2 | A null pointer was received |
    #  * | 3 | The method panicked |
    #  * | 4 | Invalid arguments were provided to the verification process |
    #  */
    Response = Hash[
      'VERIFICATION_SUCCESSFUL' => 0,
      'VERIFICATION_FAILED' => 1,
      'NULL_POINTER_RECEIVED' => 2,
      'METHOD_PANICKED' => 3,
      'INVALID_ARGUMENTS' => 4,
    ]

    attach_function :verify, :pactffi_verify, %i[string], :int32
    attach_function :new, :pactffi_verifier_new, %i[], :pointer
    attach_function :new_for_application, :pactffi_verifier_new_for_application, %i[string string], :pointer
    attach_function :shutdown, :pactffi_verifier_shutdown, %i[pointer], :void
    attach_function :set_provider_info, :pactffi_verifier_set_provider_info,
                    %i[pointer string string string ushort string], :void
    attach_function :add_provider_transport, :pactffi_verifier_add_provider_transport,
                    %i[pointer string uint16 string string], :void
    attach_function :set_filter_info, :pactffi_verifier_set_filter_info, %i[pointer string string uint8], :void
    attach_function :set_provider_state, :pactffi_verifier_set_provider_state, %i[pointer string uint8 uint8], :void
    attach_function :set_verification_options, :pactffi_verifier_set_verification_options, %i[pointer uint8 ulong_long],
                    :int32
    attach_function :set_coloured_output, :pactffi_verifier_set_coloured_output, %i[pointer uint8], :int32
    attach_function :set_no_pacts_is_error, :pactffi_verifier_set_no_pacts_is_error, %i[pointer uint8], :int32
    attach_function :set_publish_options, :pactffi_verifier_set_publish_options,
                    %i[pointer string string pointer uint16 string], :int32
    attach_function :set_consumer_filters, :pactffi_verifier_set_consumer_filters, %i[pointer pointer uint16], :void
    attach_function :add_custom_header, :pactffi_verifier_add_custom_header, %i[pointer string string], :void
    attach_function :add_file_source, :pactffi_verifier_add_file_source, %i[pointer string], :void
    attach_function :add_directory_source, :pactffi_verifier_add_directory_source, %i[pointer string], :void
    attach_function :url_source, :pactffi_verifier_url_source, %i[pointer string string string string], :void
    attach_function :broker_source, :pactffi_verifier_broker_source, %i[pointer string string string string], :void
    attach_function :broker_source_with_selectors, :pactffi_verifier_broker_source_with_selectors,
                    %i[pointer string string string string uint8 string pointer uint16 string pointer uint16 pointer uint16], :int32
    attach_function :execute, :pactffi_verifier_execute, %i[pointer], :int32
    attach_function :cli_args, :pactffi_verifier_cli_args, %i[], :string
    attach_function :logs, :pactffi_verifier_logs, %i[pointer], :string
    attach_function :logs_for_provider, :pactffi_verifier_logs_for_provider, %i[string], :string
    attach_function :output, :pactffi_verifier_output, %i[pointer uint8], :string
    attach_function :json, :pactffi_verifier_json, %i[pointer], :string
  end
end
