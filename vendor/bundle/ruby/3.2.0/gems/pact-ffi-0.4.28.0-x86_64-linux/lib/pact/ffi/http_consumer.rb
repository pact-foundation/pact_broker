# require 'pact-ffi/version'
require 'ffi'
require 'pact/detect_os'

module PactFfi
  module HttpConsumer
    extend FFI::Library
    ffi_lib DetectOS.get_bin_path

    # DetectOS.windows? || DetectOS.linux_arm? ? (typedef :uint32, :uint32_type) : (typedef :uint32_t, :uint32_type)
    (typedef :uint32, :uint32_type) 

    attach_function :pact_interaction_iter_next, :pactffi_pact_interaction_iter_next, %i[pointer], :pointer
    attach_function :pact_interaction_iter_delete, :pactffi_pact_interaction_iter_delete, %i[pointer], :void
    attach_function :new_pact, :pactffi_new_pact, %i[string string], :uint16
    attach_function :new_interaction, :pactffi_new_interaction, %i[uint16 string], :uint32_type
    attach_function :upon_receiving, :pactffi_upon_receiving, %i[uint32_type string], :bool
    attach_function :given, :pactffi_given, %i[uint32_type string], :bool
    attach_function :given_with_param, :pactffi_given_with_param, %i[uint32_type string], :bool
    attach_function :given_with_params, :pactffi_given_with_params, %i[uint32_type string string], :int32
    attach_function :interaction_test_name, :pactffi_interaction_test_name, %i[uint32_type string], :uint32_type
    attach_function :given_with_param, :pactffi_given_with_param, %i[uint32_type string string string], :bool
    attach_function :with_request, :pactffi_with_request, %i[uint32_type string string], :bool
    attach_function :with_query_parameter, :pactffi_with_query_parameter, %i[uint32_type string size_t string], :bool
    attach_function :with_query_parameter_v2, :pactffi_with_query_parameter_v2, %i[uint32_type string size_t string],
                    :bool
    attach_function :with_specification, :pactffi_with_specification, %i[uint16 int32], :bool
    attach_function :with_pact_metadata, :pactffi_with_pact_metadata, %i[uint16 string string string], :bool
    attach_function :with_header, :pactffi_with_header, %i[uint32_type int32 string size_t string], :bool
    attach_function :with_header_v2, :pactffi_with_header_v2, %i[uint32_type int32 string size_t string], :bool
    attach_function :response_status, :pactffi_response_status, %i[uint32_type uint16], :bool
    attach_function :response_status_v2, :pactffi_response_status_v2, %i[uint32_type string], :bool
    attach_function :with_body, :pactffi_with_body, %i[uint32_type int32 string string], :bool
    attach_function :with_binary_file, :pactffi_with_binary_file, %i[uint32_type int32 string pointer size_t], :bool
    attach_function :with_multipart_file, :pactffi_with_multipart_file, %i[uint32_type int32 string string string], :pointer
    attach_function :set_header, :pactffi_set_header, %i[uint32_type int32 string string], :bool
    attach_function :with_binary_body, :pactffi_with_binary_body, %i[uint32_type int32 string pointer size_t], :bool
    attach_function :with_matching_rules, :pactffi_with_matching_rules, %i[uint32_type int32 string], :bool
    attach_function :with_generators, :pactffi_with_generators, %i[uint32_type int32 string], :bool
    attach_function :with_multipart_file_v2, :pactffi_with_multipart_file_v2, %i[uint32_type int32 string string string string], :pointer
  end
end
