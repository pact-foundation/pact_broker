# frozen_string_literal: true

require 'json'
require 'yaml'

module OpenapiFirst
  # @!visibility private
  module FileLoader
    module_function

    def load(file_path)
      raise FileNotFoundError, "File not found #{file_path.inspect}" unless File.exist?(file_path)

      body = File.read(file_path)
      extname = File.extname(file_path)
      return ::JSON.parse(body) if extname == '.json'
      return YAML.unsafe_load(body) if ['.yaml', '.yml'].include?(extname)

      body
    end
  end
end
