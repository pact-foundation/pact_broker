module Approvals
  module Namers
    class DefaultNamer

      attr_reader :name
      def initialize(name = nil)
        raise ArgumentError.new("DefaultNamer: You must specify a name") if name.nil?
        @name = normalize(name)
      end

      def normalize(string)
        string.strip.squeeze(" ").gsub(/[\ :-]+/, '_').gsub(/[\W]/, '').downcase
      end

      def output_dir
        @output_dir ||= Approvals.configuration.approvals_path
      end
    end
  end
end
