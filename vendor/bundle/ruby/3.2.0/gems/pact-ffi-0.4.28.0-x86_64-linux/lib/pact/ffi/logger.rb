# require 'pact-ffi/version'
require 'ffi'
require 'pact/detect_os'

module PactFfi
  module Logger
    extend FFI::Library
    ffi_lib DetectOS.get_bin_path

    # DetectOS.windows? || DetectOS.linux_arm? ? (typedef :uint32, :uint32_type) : (typedef :uint32_t, :uint32_type)
    (typedef :uint32, :uint32_type) 

    LogLevel = Hash[
      'OFF' => 0,
      'ERROR' => 1,
      'WARN' => 2,
      'INFO' => 3,
      'DEBUG' => 4,
      'TRACE' => 5
    ]

    attach_function :enable_ansi_support, :pactffi_enable_ansi_support, %i[], :void
    attach_function :message, :pactffi_log_message, %i[string string string], :void
    attach_function :get_error_message, :pactffi_get_error_message, %i[string int32], :int32
    attach_function :log_to_stdout, :pactffi_log_to_stdout, %i[int32], :int32
    attach_function :log_to_stderr, :pactffi_log_to_stderr, %i[int32], :int32
    attach_function :log_to_file, :pactffi_log_to_file, %i[string int32], :int32
    attach_function :log_to_buffer, :pactffi_log_to_buffer, %i[int32], :int32
    attach_function :init, :pactffi_logger_init, %i[], :void
    attach_function :attach_sink, :pactffi_logger_attach_sink, %i[string int32], :int32
    attach_function :apply, :pactffi_logger_apply, %i[], :int32
    attach_function :fetch_log_buffer, :pactffi_fetch_log_buffer, %i[string], :string
  end
end
