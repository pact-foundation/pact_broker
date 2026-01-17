require 'pact/consumer_contract'
require 'pact/mock_service/interactions/interactions_filter'
require 'pact/consumer_contract/file_name'
require 'pact/consumer_contract/pact_file'
require 'pact/consumer_contract/consumer_contract_decorator'
require 'pact/shared/active_support_support'
require 'fileutils'

module Pact

  class ConsumerContractWriterError < StandardError; end

  class ConsumerContractWriter

    DEFAULT_PACT_SPECIFICATION_VERSION = '2.0.0'

    include Pact::FileName
    include Pact::PactFile
    include ActiveSupportSupport

    def initialize consumer_contract_details, logger
      @logger = logger
      @consumer_contract_details = consumer_contract_details
      @pactfile_write_mode = (consumer_contract_details[:pactfile_write_mode] || :overwrite).to_sym
      @interactions = consumer_contract_details.fetch(:interactions)
      @pact_specification_version = (consumer_contract_details[:pact_specification_version] || DEFAULT_PACT_SPECIFICATION_VERSION).to_s
      @consumer_contract_decorator_class = consumer_contract_details[:consumer_contract_decorator_class] || Pact::ConsumerContractDecorator
      @error_stream = consumer_contract_details[:error_stream] || Pact.configuration.error_stream
      @output_stream = consumer_contract_details[:output_stream] || Pact.configuration.output_stream
    end

    def consumer_contract
      @consumer_contract ||= Pact::ConsumerContract.new(
        consumer: ServiceConsumer.new(name: consumer_contract_details[:consumer][:name]),
        provider: ServiceProvider.new(name: consumer_contract_details[:provider][:name]),
        interactions: interactions_for_new_consumer_contract)
    end

    def write
      update_pactfile_if_needed
      pact_json
    end

    def can_write?
      consumer_name && provider_name && consumer_contract_details[:pact_dir]
    end

    private

    attr_reader :consumer_contract_details, :pactfile_write_mode, :interactions, :logger, :pact_specification_version, :consumer_contract_decorator_class
    attr_reader :error_stream, :output_stream

    def update_pactfile_if_needed
      return if pactfile_write_mode == :none
      return if interactions.count == 0
      update_pactfile
    end

    def update_pactfile
      logger.info log_message
      FileUtils.mkdir_p File.dirname(pactfile_path)
      # must be read after obtaining the lock, and must be read from the yielded file object, otherwise windows freaks out
      # https://apidock.com/ruby/File/flock
      File.open(pactfile_path, File::RDWR|File::CREAT, 0644) {|pact_file|
        pact_file.flock(File::LOCK_EX)
        @existing_contents = pact_file.read
        new_contents = pact_json
        pact_file.rewind
        pact_file.truncate 0
        pact_file.write new_contents
        pact_file.flush
        pact_file.truncate(pact_file.pos)
      }
    end

    def pact_json
      @pact_json ||= fix_json_formatting(JSON.pretty_generate(decorated_pact))
    end

    def decorated_pact
      @decorated_pact ||= consumer_contract_decorator_class.new(consumer_contract, pact_specification_version: pact_specification_version)
    end

    def interactions_for_new_consumer_contract
      if pactfile_exists? && (updating? || merging?)
        merged_interactions = existing_interactions.dup
        filter = Pact::MockService::Interactions.filter(merged_interactions, pactfile_write_mode)
        interactions.each {|i| filter << i }
        merged_interactions
      else
        interactions
      end
    end

    def existing_interactions
      interactions = []
      if pactfile_exists? && pactfile_has_contents?
        begin
          interactions = existing_consumer_contract.interactions
          print_updating_warning if updating?
        rescue StandardError => e
          warn_and_stderr "Could not load existing consumer contract from #{pactfile_path} due to #{e}. Creating a new file."
          logger.error e
          logger.error e.backtrace
        end
      end
      interactions
    end

    def pactfile_exists?
      File.exist?(pactfile_path)
    end

    def pactfile_has_contents?
      File.size(pactfile_path) != 0
    end

    def existing_contents
      @existing_contents
    end

    def existing_consumer_contract
      @existing_consumer_contract ||= Pact::ConsumerContract.from_json(existing_contents)
    end

    def warn_and_stderr msg
      error_stream.puts msg
      logger.warn msg
    end

    def info_and_puts msg
      output_stream.puts msg
      logger.info msg
    end

    def consumer_name
      consumer_contract_details[:consumer][:name]
    end

    def provider_name
      consumer_contract_details[:provider][:name]
    end

    def pactfile_path
      raise 'You must specify a consumer and provider name' unless (consumer_name && provider_name)
      file_path consumer_name, provider_name, pact_dir, unique: consumer_contract_details[:unique_pact_file_names]
    end

    def pact_dir
      unless consumer_contract_details[:pact_dir]
        raise ConsumerContractWriterError.new("Please indicate the directory to write the pact to by specifying the pact_dir field")
      end
      consumer_contract_details[:pact_dir]
    end

    def updating?
      pactfile_write_mode == :update
    end

    def merging?
      pactfile_write_mode == :merge
    end

    def log_message
      if updating?
        "Updating pact for #{provider_name} at #{pactfile_path}"
      elsif merging?
        "Merging interactions into pact for #{provider_name} at #{pactfile_path}"
      else
        "Writing pact for #{provider_name} to #{pactfile_path}"
      end
    end

    def print_updating_warning
      info_and_puts "*****************************************************************************"
      info_and_puts "Updating existing file .#{pactfile_path.gsub(Dir.pwd, '')} as pactfile_write_mode is :update"
      info_and_puts "Only interactions defined in this test run will be updated."
      info_and_puts "As interactions are identified by description and provider state, pleased note that if either of these have changed, the old interactions won't be removed from the pact file until the specs are next run with :pactfile_write_mode => :overwrite."
      info_and_puts "*****************************************************************************"
    end
  end
end
