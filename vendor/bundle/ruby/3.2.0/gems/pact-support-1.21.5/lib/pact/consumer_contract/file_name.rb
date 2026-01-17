module Pact
  module FileName
    extend self

    def file_name consumer_name, provider_name, options = {}
      pid = options[:unique] ? "-#{Process.pid}" : ''
      "#{filenamify(consumer_name)}-#{filenamify(provider_name)}#{pid}.json"
    end

    def file_path consumer_name, provider_name, pact_dir = Pact.configuration.pact_dir, options = {}
      File.join(windows_safe(pact_dir), file_name(consumer_name, provider_name, options))
    end

    def filenamify name
      name.downcase.gsub(/\s/, '_')
    end

    def windows_safe(pact_dir)
      pact_dir.gsub("\\", "/")
    end
  end
end
