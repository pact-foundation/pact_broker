# require 'pact-ffi/version'
require 'ffi'
require 'pact/detect_os'

module PactFfi
  module SyncHttpConsumer
    extend FFI::Library
    ffi_lib DetectOS.get_bin_path

    # DetectOS.windows? || DetectOS.linux_arm? ? (typedef :uint32, :uint32_type) : (typedef :uint32_t, :uint32_type)
    (typedef :uint32, :uint32_type) 

    attach_function :new, :pactffi_sync_http_new, %i[], :pointer
    attach_function :delete, :pactffi_sync_http_delete, %i[pointer], :void
    attach_function :get_request, :pactffi_sync_http_get_request, %i[pointer], :pointer
    attach_function :get_request_contents, :pactffi_sync_http_get_request_contents, %i[pointer], :string
    attach_function :set_request_contents, :pactffi_sync_http_set_request_contents, %i[pointer string string], :void
    attach_function :get_request_contents_length, :pactffi_sync_http_get_request_contents_length, %i[pointer], :size_t
    attach_function :get_request_contents_bin, :pactffi_sync_http_get_request_contents_bin, %i[pointer], :pointer
    attach_function :set_request_contents_bin, :pactffi_sync_http_set_request_contents_bin, %i[pointer pointer size_t string], :void
    attach_function :get_response, :pactffi_sync_http_get_response, %i[pointer], :pointer
    attach_function :get_response_contents, :pactffi_sync_http_get_response_contents, %i[pointer], :string
    attach_function :set_response_contents, :pactffi_sync_http_set_response_contents, %i[pointer string string], :void
    attach_function :get_response_contents_length, :pactffi_sync_http_get_response_contents_length, %i[pointer], :size_t
    attach_function :get_response_contents_bin, :pactffi_sync_http_get_response_contents_bin, %i[pointer], :pointer
    attach_function :set_response_contents_bin, :pactffi_sync_http_set_response_contents_bin, %i[pointer pointer size_t string], :void
    attach_function :get_description, :pactffi_sync_http_get_description, %i[pointer], :string
    attach_function :set_description, :pactffi_sync_http_set_description, %i[pointer string], :int32
    attach_function :get_provider_state, :pactffi_sync_http_get_provider_state, %i[pointer uint32_type], :pointer
    attach_function :get_provider_state_iter, :pactffi_sync_http_get_provider_state_iter, %i[pointer], :pointer
    attach_function :pact_interaction_as_synchronous_http, :pactffi_pact_interaction_as_synchronous_http, %i[pointer], :pointer
    attach_function :iter_next, :pactffi_pact_sync_http_iter_next, %i[pointer], :pointer
    attach_function :iter_delete, :pactffi_pact_sync_http_iter_delete, %i[pointer], :void
    attach_function :pact_handle_get_sync_http_iter, :pactffi_pact_handle_get_sync_http_iter, %i[uint16], :pointer
  end
end
