# require 'pact-ffi/version'
require 'ffi'
require 'pact/detect_os'

module PactFfi
  module SyncMessageConsumer
    extend FFI::Library
    ffi_lib DetectOS.get_bin_path

    # DetectOS.windows? || DetectOS.linux_arm? ? (typedef :uint32, :uint32_type) : (typedef :uint32_t, :uint32_type)
    (typedef :uint32, :uint32_type) 

    attach_function :pact_interaction_as_synchronous_message, :pactffi_pact_interaction_as_synchronous_message, %i[pointer], :pointer
    attach_function :iter_next, :pactffi_pact_sync_message_iter_next, %i[pointer], :pointer
    attach_function :iter_delete, :pactffi_pact_sync_message_iter_delete, %i[pointer], :void
    attach_function :new, :pactffi_sync_message_new, %i[], :pointer
    attach_function :delete, :pactffi_sync_message_delete, %i[pointer], :void
    attach_function :get_request_contents_str, :pactffi_sync_message_get_request_contents_str, %i[pointer], :string
    attach_function :set_request_contents_str, :pactffi_sync_message_set_request_contents_str, %i[pointer string string], :void
    attach_function :get_request_contents_length, :pactffi_sync_message_get_request_contents_length, %i[pointer], :size_t
    attach_function :get_request_contents_bin, :pactffi_sync_message_get_request_contents_bin, %i[pointer], :pointer
    attach_function :set_request_contents_bin, :pactffi_sync_message_set_request_contents_bin, %i[pointer pointer size_t string], :void
    attach_function :get_request_contents, :pactffi_sync_message_get_request_contents, %i[pointer], :pointer
    attach_function :generate_request_contents, :pactffi_sync_message_generate_request_contents, %i[pointer], :pointer
    attach_function :get_number_responses, :pactffi_sync_message_get_number_responses, %i[pointer], :size_t
    attach_function :get_response_contents_str, :pactffi_sync_message_get_response_contents_str, %i[pointer size_t], :string
    attach_function :set_response_contents_str, :pactffi_sync_message_set_response_contents_str, %i[pointer size_t string string], :void
    attach_function :get_response_contents_length, :pactffi_sync_message_get_response_contents_length, %i[pointer size_t], :size_t
    attach_function :get_response_contents_bin, :pactffi_sync_message_get_response_contents_bin, %i[pointer size_t], :pointer
    attach_function :set_response_contents_bin, :pactffi_sync_message_set_response_contents_bin, %i[pointer size_t pointer size_t string], :void
    attach_function :get_response_contents, :pactffi_sync_message_get_response_contents, %i[pointer size_t], :pointer
    attach_function :get_description, :pactffi_sync_message_get_description, %i[pointer], :string
    attach_function :set_description, :pactffi_sync_message_set_description, %i[pointer string], :int32
    attach_function :get_provider_state, :pactffi_sync_message_get_provider_state, %i[pointer uint32_type], :pointer
    attach_function :get_provider_state_iter, :pactffi_sync_message_get_provider_state_iter, %i[pointer], :pointer
    attach_function :new_interaction, :pactffi_new_sync_message_interaction, %i[uint16 string], :uint32_type
    attach_function :get_iter, :pactffi_pact_handle_get_sync_message_iter, %i[uint16], :pointer
  end
end
