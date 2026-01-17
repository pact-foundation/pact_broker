# require 'pact-ffi/version'
require 'ffi'
require 'pact/detect_os'

module PactFfi
  module AsyncMessageConsumer
    extend FFI::Library
    ffi_lib DetectOS.get_bin_path

    # DetectOS.windows? || DetectOS.linux_arm? ? (typedef :uint32, :uint32_type) : (typedef :uint32_t, :uint32_type)
    (typedef :uint32, :uint32_type)

    attach_function :new_async_message, :pactffi_async_message_new, %i[], :pointer
    attach_function :delete, :pactffi_async_message_delete, %i[pointer], :void
    attach_function :get_contents, :pactffi_async_message_get_contents, %i[pointer], :pointer
    attach_function :generate_contents, :pactffi_async_message_generate_contents, %i[pointer], :pointer
    attach_function :get_contents_str, :pactffi_async_message_get_contents_str, %i[pointer], :string
    attach_function :set_contents_str, :pactffi_async_message_set_contents_str, %i[pointer string string], :void
    attach_function :get_contents_length, :pactffi_async_message_get_contents_length, %i[pointer], :size_t
    attach_function :get_contents_bin, :pactffi_async_message_get_contents_bin, %i[pointer], :pointer
    attach_function :set_contents_bin, :pactffi_async_message_set_contents_bin, %i[pointer pointer size_t string], :void
    attach_function :get_description, :pactffi_async_message_get_description, %i[pointer], :string
    attach_function :set_description, :pactffi_async_message_set_description, %i[pointer string], :int32
    attach_function :get_provider_state, :pactffi_async_message_get_provider_state, %i[pointer uint32_type], :pointer
    attach_function :get_provider_state_iter, :pactffi_async_message_get_provider_state_iter, %i[pointer], :pointer
    attach_function :new, :pactffi_new_async_message, %i[uint16 string], :uint32_type
    attach_function :pact_interaction_as_asynchronous_message, :pactffi_pact_interaction_as_asynchronous_message,
                    %i[pointer], :pointer
    attach_function :iter_next, :pactffi_pact_async_message_iter_next, %i[pointer], :pointer
    attach_function :iter_delete, :pactffi_pact_async_message_iter_delete, %i[pointer], :void
    attach_function :get_iter, :pactffi_pact_handle_get_async_message_iter, %i[uint16], :pointer
  end
end
