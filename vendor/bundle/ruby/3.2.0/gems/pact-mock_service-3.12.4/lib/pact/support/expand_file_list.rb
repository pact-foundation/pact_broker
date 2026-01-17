module Pact
  module Support
    module ExpandFileList
      def self.call pact_files
        pact_files
          .collect{ |path| unixify_path(path) }
          .collect{ | path | expand_path(path) }
          .flatten
      end

      def self.unixify_path(path)
        path.gsub(/\\+/, '/')
      end

      def self.expand_path(path)
        if File.directory?(path)
          Dir.glob(File.join(path, "*.json"))
        elsif Dir.glob(path).any?
          Dir.glob(path)
        else
          path
        end
      end
    end
  end
end
