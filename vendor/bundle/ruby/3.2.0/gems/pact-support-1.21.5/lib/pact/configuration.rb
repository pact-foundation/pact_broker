require 'pact/matchers/embedded_diff_formatter'
require 'pact/matchers/unix_diff_formatter'
require 'pact/matchers/list_diff_formatter'
require 'pact/matchers/multipart_form_diff_formatter'
require 'pact/shared/json_differ'
require 'pact/shared/text_differ'
require 'pact/shared/form_differ'
require 'pact/shared/multipart_form_differ'
require 'rainbow'


module Pact

  class Configuration

    DIFF_FORMATTERS = {
      :embedded => Pact::Matchers::EmbeddedDiffFormatter,
      :unix => Pact::Matchers::UnixDiffFormatter,
      :list => Pact::Matchers::ListDiffFormatter
    }


    class NilMatcher
      def self.=~ other
        other == nil ? 0 : nil
      end
    end

    DIFF_FORMATTER_REGISTRATIONS = [
      [/multipart\/form-data/, Pact::Matchers::MultipartFormDiffFormatter],
      [/.*/, Pact::Matchers::UnixDiffFormatter],
      [NilMatcher, Pact::Matchers::UnixDiffFormatter]
    ]

    DIFFERS = [
      [/json/, Pact::JsonDiffer],
      [/application\/x\-www\-form\-urlencoded/, Pact::FormDiffer],
      [/multipart\/form-data/, Pact::MultipartFormDiffer],
      [NilMatcher, Pact::TextDiffer],
      [/.*/, Pact::TextDiffer]
    ]


    DEFAULT_DIFFER = Pact::TextDiffer

    attr_accessor :pact_dir
    attr_accessor :log_dir
    attr_accessor :tmp_dir

    attr_writer :logger

    attr_accessor :error_stream
    attr_accessor :output_stream
    attr_accessor :pactfile_write_order
    attr_accessor :treat_all_number_classes_as_equivalent # when using type based matching

    def self.default_configuration
      c = Configuration.new
      c.pact_dir = File.expand_path('./spec/pacts')
      c.tmp_dir = File.expand_path('./tmp/pacts')
      c.log_dir = default_log_dir

      c.output_stream = $stdout
      c.error_stream = $stderr
      c.pactfile_write_order = :chronological
      c.treat_all_number_classes_as_equivalent = true

      c
    end

    def initialize
      @differ_registrations = []
      @diff_formatter_registrations = []
    end

    def logger
      @logger ||= create_logger
    end

    # Should this be deprecated in favour of register_diff_formatter???
    def diff_formatter= diff_formatter
      register_diff_formatter(/.*/, diff_formatter)
      register_diff_formatter(nil, diff_formatter)
    end

    def register_diff_formatter content_type, diff_formatter
      key = content_type_regexp_for content_type
      @diff_formatter_registrations << [key, diff_formatter_for(diff_formatter)]
    end

    def diff_formatter_for_content_type content_type
      diff_formatter_registrations.find{ | registration | registration.first =~ content_type }.last
    end

    def register_body_differ content_type, differ
      key = content_type_regexp_for content_type
      validate_differ differ
      @differ_registrations << [key, differ]
    end

    def body_differ_for_content_type content_type
      differ_registrations
        .find{ | registration | registration.first =~ content_type }
        .tap do |it|
          if content_type.nil? && it.last == Pact::TextDiffer
            error_stream.puts "WARN: No content type found, performing text diff on body"
            logger.warn "No content type found, performing text diff on body"
          end
        end.last
    end

    def log_path
      log_dir + "/pact.log"
    end

    def color_enabled
      # Can't use ||= when the variable might be false, it will execute the expression if it's false
      color_enabled = defined?(@color_enabled) ? @color_enabled : true
      Rainbow.enabled = true if color_enabled
      color_enabled
    end

    def color_enabled= color_enabled
      @color_enabled = color_enabled
    end

    private

    def diff_formatter_for input
      if DIFF_FORMATTERS[input]
        DIFF_FORMATTERS[input]
      elsif input.respond_to?(:call)
        input
      else
        raise "Pact diff_formatter needs to respond to call, or be in the preconfigured list: #{DIFF_FORMATTERS.keys}"
      end
    end

    def validate_differ differ
      if !differ.respond_to?(:call)
        raise "Pact.configuration.register_body_differ expects a differ that is a lamda or a class/object that responds to call."
      end
    end

    def content_type_regexp_for content_type
      case content_type
      when String then Regexp.new(/^#{Regexp.escape(content_type)}$/)
      when Regexp then content_type
      when nil then NilMatcher
      else
        raise "Invalid content type used to register a differ (#{content_type.inspect}). Please use a Regexp or a String."
      end
    end

    def differ_registrations
      @differ_registrations + DIFFERS
    end

    def diff_formatter_registrations
      @diff_formatter_registrations + DIFF_FORMATTER_REGISTRATIONS
    end

    def self.default_log_dir
      File.expand_path("./log")
    end

    #Would love a better way of determining this! It sure won't work on windows.
    def is_rake_running?
      `ps -ef | grep rake | grep #{Process.ppid} | grep -v 'grep'`.size > 0
    end

    def create_logger
      FileUtils::mkdir_p log_dir
      logger = ::Logger.new(log_path)
      logger.level = ::Logger::DEBUG
      logger
    rescue Errno::EROFS
      # So we can run on RunKit
      logger = ::Logger.new($stdout)
      logger.level = ::Logger::DEBUG
      logger
    end
  end

  def self.configuration
    @configuration ||= Configuration.default_configuration
  end

  def self.configure
    yield configuration
  end

  def self.clear_configuration
    @configuration = nil
  end
end
